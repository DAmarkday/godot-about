# 设计文档：回合制战棋游戏

## 概述

本文档描述基于 Godot 4 + GDScript 的回合制战棋游戏的技术设计。游戏参考《陷阵之志》风格，在小型格子地图上进行回合制战斗。

设计核心原则：
- **模块解耦**：各系统通过 EventBus 信号通信，不直接持有彼此引用
- **数据驱动**：棋子属性通过 Resource 配置文件定义，与逻辑代码分离
- **可叠加组合**：每个系统可独立运行，也可组合使用

---

## 架构

### 整体架构图

```
┌─────────────────────────────────────────────────────────┐
│                      BattleScene                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │TurnManager│  │UnitManager│  │BattleMap │  │UI Layer│  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘  │
│       │              │              │              │      │
│       └──────────────┴──────────────┴──────────────┘     │
│                           │                              │
│                      EventBus（全局信号总线）              │
│                           │                              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │MovementSystem│  │CombatSystem  │  │AIController   │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 场景树结构

```
BattleScene (Node2D)
├── BattleMap (Node2D)                    # 地图根节点
│   ├── TileMapLayer0                     # 基础地形层（陆地/河流）
│   ├── TileMapLayer1                     # 装饰层（森林/山地）
│   ├── HighlightLayer (TileMapLayer)     # 高亮层（移动/攻击范围）
│   └── UnitsContainer (Node2D)          # 棋子容器
│       ├── PlayerUnits (Node2D)          # 玩家棋子
│       └── EnemyUnits (Node2D)           # 敌方棋子
├── Systems (Node)                        # 系统节点容器（不渲染）
│   ├── TurnManager (Node)               # 回合管理器
│   ├── UnitManager (Node)               # 棋子管理器
│   ├── MovementSystem (Node)            # 移动系统
│   ├── CombatSystem (Node)              # 战斗系统
│   └── AIController (Node)              # AI 控制器
└── UILayer (CanvasLayer)                 # UI 层
    ├── TurnPanel                         # 回合信息面板
    ├── UnitInfoPanel                     # 棋子信息面板
    └── EndTurnButton                     # 结束回合按钮
```

### 模块通信流程

```
玩家点击格子
    │
    ▼
BattleScene._input()
    │
    ├─→ MovementSystem.try_move(unit, target_cell)
    │       │
    │       └─→ EventBus.emit(unit_moved, ...)
    │               │
    │               ├─→ UnitManager.update_position()
    │               └─→ UILayer.refresh()
    │
    └─→ CombatSystem.try_attack(attacker, target_cell)
            │
            └─→ EventBus.emit(attack_performed, ...)
                    │
                    ├─→ UnitManager.apply_damage()
                    └─→ UILayer.refresh()
```

---

## 组件与接口

### EventBus（全局信号总线）

路径：`script/EventBus.gd`，作为 AutoLoad 注册为全局单例。

```gdscript
# 棋子相关信号
signal unit_selected(unit: Unit)           # 棋子被选中
signal unit_deselected(unit: Unit)         # 棋子取消选中
signal unit_moved(unit: Unit, from: Vector2i, to: Vector2i)   # 棋子移动完成
signal unit_damaged(unit: Unit, damage: int, remaining_hp: int) # 棋子受伤
signal unit_died(unit: Unit, team: int)    # 棋子死亡

# 战斗相关信号
signal attack_performed(attacker: Unit, target: Unit, damage: int) # 攻击发生

# 回合相关信号
signal turn_changed(new_state: TurnManager.TurnState, turn_number: int) # 回合变化
signal player_turn_started(turn_number: int)   # 玩家回合开始
signal enemy_turn_started(turn_number: int)    # 敌方回合开始

# 游戏结果信号
signal battle_won()    # 玩家胜利
signal battle_lost()   # 玩家失败
```

### UnitData（棋子配置 Resource）

路径：`script/data/UnitData.gd`

```gdscript
class_name UnitData extends Resource

@export var unit_name: String = "士兵"
@export var max_hp: int = 10
@export var movement: int = 3       # 移动力
@export var attack_power: int = 3   # 攻击力
@export var defense: int = 1        # 防御力
@export var attack_range: int = 1   # 攻击范围（格子数）
@export var team: int = 0           # 0=玩家, 1=敌方
@export var sprite_frames: SpriteFrames  # 动画资源
```

### Unit（棋子节点）

路径：`script/unit/Unit.gd`，继承 `CharacterBody2D`

```gdscript
class_name Unit extends CharacterBody2D

# 从 UnitData 加载的属性
var unit_name: String
var max_hp: int
var current_hp: int
var movement: int
var attack_power: int
var defense: int
var attack_range: int
var team: int  # 0=玩家, 1=敌方

# 运行时状态
var grid_position: Vector2i
var has_moved: bool = false      # 本回合是否已移动
var has_attacked: bool = false   # 本回合是否已攻击
var is_alive: bool = true

# 初始化方法
func setup(data: UnitData) -> void

# 受伤（由 CombatSystem 调用）
func take_damage(amount: int) -> void

# 重置行动点（由 TurnManager 调用）
func reset_actions() -> void
```

### TurnManager（回合管理器）

路径：`script/systems/TurnManager.gd`，继承 `Node`

```gdscript
class_name TurnManager extends Node

enum TurnState {
    PLAYER_TURN,   # 玩家回合
    ENEMY_TURN,    # 敌方回合
    GAME_OVER      # 游戏结束
}

var current_state: TurnState
var turn_number: int = 0

func start_battle() -> void          # 开始战斗（进入第1回合玩家阶段）
func end_player_turn() -> void       # 玩家结束回合
func end_enemy_turn() -> void        # 敌方结束回合（由 AIController 调用）
func end_game(player_won: bool) -> void  # 结束游戏
```

### UnitManager（棋子管理器）

路径：`script/systems/UnitManager.gd`，继承 `Node`

```gdscript
class_name UnitManager extends Node

# 注册棋子
func register_unit(unit: Unit) -> void

# 注销棋子（死亡时）
func unregister_unit(unit: Unit) -> void

# 查询格子上的棋子
func get_unit_at(cell: Vector2i) -> Unit

# 更新棋子位置记录
func update_unit_position(unit: Unit, new_cell: Vector2i) -> void

# 获取所有存活的玩家/敌方棋子
func get_player_units() -> Array[Unit]
func get_enemy_units() -> Array[Unit]

# 检查胜负条件
func check_battle_result() -> void
```

### MovementSystem（移动系统）

路径：`script/systems/MovementSystem.gd`，继承 `Node`

```gdscript
class_name MovementSystem extends Node

# 计算棋子可移动范围（返回可达格子列表）
func calculate_reachable_cells(unit: Unit, map_data: MapData) -> Array[Vector2i]

# 尝试移动棋子（含合法性校验）
func try_move(unit: Unit, target_cell: Vector2i, map_data: MapData) -> bool

# 执行移动动画
func animate_movement(unit: Unit, path: Array[Vector2i], map_data: MapData) -> void
```

### CombatSystem（战斗系统）

路径：`script/systems/CombatSystem.gd`，继承 `Node`

```gdscript
class_name CombatSystem extends Node

# 计算攻击范围（返回可攻击格子列表）
func calculate_attack_cells(unit: Unit) -> Array[Vector2i]

# 尝试攻击（含合法性校验）
func try_attack(attacker: Unit, target_cell: Vector2i, unit_manager: UnitManager) -> bool

# 计算伤害值
func calculate_damage(attacker: Unit, target: Unit) -> int
```

### AIController（AI 控制器）

路径：`script/systems/AIController.gd`，继承 `Node`

```gdscript
class_name AIController extends Node

# 执行敌方回合（异步，逐个棋子行动）
func execute_enemy_turn(
    enemy_units: Array[Unit],
    player_units: Array[Unit],
    map_data: MapData,
    movement_system: MovementSystem,
    combat_system: CombatSystem
) -> void

# 为单个敌方棋子决策行动
func decide_action(
    enemy: Unit,
    player_units: Array[Unit],
    map_data: MapData
) -> void
```

### MapGenerator（地图生成器）

路径：`script/map/MapGenerator.gd`，继承 `RefCounted`（保留现有实现，扩展出生点逻辑）

新增接口：
```gdscript
# 生成战斗地图（含出生点保障）
func generate_battle_map(width: int, height: int, seed_value: int) -> MapData
```

---

## 数据模型

### MapData（地图数据）

保留现有实现，地形类型：

| 地形 | 枚举值 | 移动成本 | 可通行 |
|------|--------|----------|--------|
| 虚空 | VOID=0 | INF | 否 |
| 陆地 | LAND=1 | 1.0 | 是 |
| 河流 | RIVER=2 | INF | 否 |
| 山地 | MOUNTAIN=3 | INF | 否 |
| 森林 | FOREST=4 | 2.0 | 是 |
| 村庄 | VILLAGE=5 | 1.0 | 是 |

### Unit 运行时状态

```
Unit {
    // 静态属性（来自 UnitData）
    unit_name: String
    max_hp: int
    movement: int
    attack_power: int
    defense: int
    attack_range: int
    team: int

    // 动态状态
    current_hp: int
    grid_position: Vector2i
    has_moved: bool
    has_attacked: bool
    is_alive: bool
}
```

### TurnManager 状态机

```
[开始] ──→ PLAYER_TURN
               │
               │ 玩家点击"结束回合"
               ▼
           ENEMY_TURN
               │
               │ AIController 完成所有敌方行动
               ▼
           PLAYER_TURN（turn_number + 1）
               │
               │ 胜负条件触发
               ▼
           GAME_OVER
```

---

## 正确性属性

*属性（Property）是对系统在所有合法输入下都应成立的行为规则——它是人类可读规范与可验证正确性保证之间的桥梁。*

### 属性 1：移动范围不超过移动力

*对于任意* 棋子（移动力 ∈ [1, 10]）和随机生成的地图，`calculate_reachable_cells` 返回的所有格子，其从起点出发的最短路径成本均不超过该棋子的 `movement` 值。

**验证：需求 2.1、2.2**

### 属性 2：移动成功后位置与信号一致

*对于任意* 棋子和其可达范围内的目标格子，调用 `try_move` 成功后：棋子的 `grid_position` 等于目标格子，且 `unit_moved` 信号被发出并携带正确的起始和目标格子。

**验证：需求 2.3、2.7**

### 属性 3：非法移动目标被拒绝

*对于任意* 棋子，当目标格子已被其他棋子占据，或目标格子不在可达范围内时，`try_move` 应返回 `false` 且棋子位置不变。

**验证：需求 2.5、2.6**

### 属性 4：伤害计算下界

*对于任意* 攻击力 ∈ [1, 20] 和防御力 ∈ [0, 20] 的组合，`calculate_damage` 的返回值始终 ≥ 1。

**验证：需求 3.3**

### 属性 5：攻击范围格子距离正确性

*对于任意* 棋子（攻击范围 ∈ [1, 5]），`calculate_attack_cells` 返回的所有格子，其与棋子当前位置的曼哈顿距离均不超过该棋子的 `attack_range` 值。

**验证：需求 3.1**

### 属性 6：行动点重置完整性

*对于任意* 数量（1 到 10 个）和任意初始行动状态的棋子集合，调用 `reset_actions()` 后，所有棋子的 `has_moved` 和 `has_attacked` 均为 `false`。

**验证：需求 4.4、4.5**

### 属性 7：回合数单调递增

*对于任意* 初始回合数，每次完整的玩家回合 + 敌方回合循环后，`turn_number` 恰好增加 1。

**验证：需求 4.6**

### 属性 8：地图序列化往返一致性

*对于任意* 合法的 MapData 对象（随机种子生成），将其序列化为 JSON 后再反序列化，所有格子的地形类型应与原始对象完全相同。

**验证：需求 5.7、5.8**

### 属性 9：相同种子生成相同地图

*对于任意* 相同的宽度、高度和种子值，两次调用 `generate_battle_map` 应生成完全相同的地图（所有格子地形类型一致）。

**验证：需求 5.6**

### 属性 10：出生区域全为陆地

*对于任意* 随机种子生成的战斗地图，玩家出生区域（左下角 3×3）和敌方出生区域（右上角 3×3）内的所有格子地形类型均为 LAND。

**验证：需求 5.4、5.5**

---

## 错误处理

| 错误场景 | 处理方式 |
|----------|----------|
| 移动目标格子被占据 | `try_move` 返回 `false`，不移动，不消耗行动点 |
| 移动目标超出范围 | `try_move` 返回 `false` |
| 攻击目标不在范围内 | `try_attack` 返回 `false` |
| 攻击目标格子无敌方棋子 | `try_attack` 返回 `false` |
| 棋子本回合已移动/攻击 | 对应方法返回 `false` |
| 非玩家回合接受玩家输入 | `BattleScene` 忽略输入事件 |
| 地图文件不存在或格式错误 | `MapData.load_from_file` 返回 `null` 并输出错误日志 |
| UnitData 资源未配置 | `Unit.setup()` 使用默认值并输出警告日志 |

---

## 测试策略

### 双轨测试方法

本项目采用**单元测试 + 属性测试**双轨策略：

- **单元测试**：验证具体示例、边界条件和错误处理
- **属性测试**：验证对所有合法输入都成立的普遍规律

两者互补，共同保证系统正确性。

### 属性测试配置

- 使用 GUT（Godot Unit Testing）框架
- 每个属性测试至少运行 100 次随机输入
- 每个属性测试用注释标注对应的设计属性编号
- 标注格式：`# Feature: tactical-chess-game, Property N: <属性描述>`

### 单元测试重点

- 伤害计算边界（攻击力 ≤ 防御力时，伤害应为 1）
- 移动力为 0 时，可达范围应为空
- 回合状态机的合法转换路径
- 地图生成的连通性保证

### 属性测试重点

对应设计文档中的 9 个正确性属性，每个属性对应一个属性测试用例：

| 属性 | 测试方法 | 随机输入 |
|------|----------|----------|
| 属性 1 | 随机生成棋子和目标格子，执行移动后比较位置 | 棋子位置、目标格子 |
| 属性 2 | 随机生成地图和棋子，验证所有可达格子的路径成本 | 地图种子、棋子移动力 |
| 属性 3 | 随机生成攻击力和防御力，验证伤害 ≥ 1 | 攻击力 [1,20]、防御力 [0,20] |
| 属性 4 | 随机生成棋子集合，调用 reset_actions 后验证状态 | 棋子数量和初始状态 |
| 属性 5 | 随机生成地图，序列化后反序列化，比较所有格子 | 地图种子、尺寸 |
| 属性 6 | 相同参数调用两次生成器，比较所有格子 | 种子、宽高 |
| 属性 7 | 随机种子生成地图，检查出生区域格子类型 | 地图种子 |
| 属性 8 | 随机生成死亡棋子，验证系统拒绝其行动 | 棋子属性 |
| 属性 9 | 随机生成棋子，验证攻击范围内所有格子的曼哈顿距离 | 棋子位置、攻击范围值 |
