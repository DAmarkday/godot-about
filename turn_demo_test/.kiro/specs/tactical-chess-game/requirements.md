# 需求文档

## 简介

本项目是一款基于 Godot 4 + GDScript 开发的回合制战棋 2D 游戏，风格参考《陷阵之志》（Into the Breach）。游戏在小型格子地图上进行，玩家控制己方棋子与敌方棋子轮流行动，每个棋子拥有独立的移动力、攻击范围和技能。地图由程序随机生成，包含多种地形类型。系统采用模块化设计，各模块高内聚低耦合，可独立组合使用。

项目已有部分旧代码（棋盘渲染、格子映射、地图生成、移动范围计算、血量系统），本次需求将在此基础上重新设计并重建整个游戏系统。

---

## 词汇表

- **棋子（Unit）**：地图上可行动的角色，分为玩家棋子和敌方棋子
- **格子（Cell）**：地图的最小单位，由 Vector2i 坐标标识
- **移动力（Movement）**：棋子每回合可移动的最大格子数（考虑地形成本）
- **攻击范围（AttackRange）**：棋子可攻击的格子集合
- **回合（Turn）**：一次完整的玩家行动阶段 + 敌方行动阶段
- **行动点（ActionPoint）**：棋子每回合可执行的操作次数（移动、攻击各消耗一次）
- **地形（Terrain）**：格子的地面类型，影响移动成本和可通行性
- **TurnManager**：回合管理器，控制回合流转和行动顺序
- **UnitManager**：棋子管理器，负责棋子的注册、查询和生命周期
- **BattleMap**：战斗地图，整合地图数据与棋子位置信息
- **AIController**：敌方 AI 控制器，负责敌方棋子的自动决策
- **SkillSystem**：技能系统，管理棋子的主动/被动技能
- **EventBus**：全局事件总线，用于模块间解耦通信

---

## 需求

### 需求 1：棋子属性与类型系统

**用户故事：** 作为玩家，我希望每个棋子拥有独立的属性（移动力、攻击力、血量等），以便不同棋子有不同的战术价值。

#### 验收标准

1. THE Unit_System SHALL 为每个棋子定义以下基础属性：单位名称、最大血量、当前血量、移动力、攻击力、攻击范围、防御力、所属阵营
2. WHEN 棋子血量降至 0，THE Unit_System SHALL 将该棋子标记为死亡并从地图上移除
3. THE Unit_System SHALL 支持通过 Resource 配置文件（UnitData）定义棋子属性，使棋子数据与逻辑代码分离
4. WHERE 棋子属于玩家阵营，THE Unit_System SHALL 允许玩家在回合内对其发出移动和攻击指令
5. WHERE 棋子属于敌方阵营，THE Unit_System SHALL 由 AIController 控制其行动
6. WHEN 棋子受到伤害，THE Unit_System SHALL 发出 unit_damaged 信号，携带棋子引用、伤害值和剩余血量
7. WHEN 棋子死亡，THE Unit_System SHALL 发出 unit_died 信号，携带棋子引用和所属阵营

---

### 需求 2：移动系统

**用户故事：** 作为玩家，我希望选中棋子后能看到可移动范围高亮，并点击目标格子完成移动，以便直观地操控棋子。

#### 验收标准

1. WHEN 玩家选中一个己方棋子，THE Movement_System SHALL 计算并高亮显示该棋子本回合可到达的所有格子
2. THE Movement_System SHALL 根据棋子的移动力和地形移动成本计算可达范围（陆地成本=1，森林成本=2，山地不可通行，河流不可通行）
3. WHEN 玩家点击可移动范围内的目标格子，THE Movement_System SHALL 沿最短路径移动棋子并播放移动动画
4. WHEN 棋子本回合已移动，THE Movement_System SHALL 禁止该棋子再次移动，直到下一回合
5. IF 目标格子已被其他棋子占据，THEN THE Movement_System SHALL 拒绝移动并保持棋子在原位
6. IF 目标格子不在可移动范围内，THEN THE Movement_System SHALL 拒绝移动并保持棋子在原位
7. WHEN 棋子移动完成，THE Movement_System SHALL 发出 unit_moved 信号，携带棋子引用、起始格子和目标格子

---

### 需求 3：攻击与战斗系统

**用户故事：** 作为玩家，我希望选中棋子后能看到攻击范围，并点击敌方棋子发动攻击，以便消灭敌人。

#### 验收标准

1. WHEN 玩家选中一个本回合未攻击的己方棋子，THE Combat_System SHALL 计算并高亮显示该棋子的攻击范围
2. WHEN 玩家点击攻击范围内的敌方棋子，THE Combat_System SHALL 计算伤害并扣除目标血量
3. THE Combat_System SHALL 按公式计算伤害：最终伤害 = max(1, 攻击力 - 目标防御力)
4. WHEN 棋子本回合已攻击，THE Combat_System SHALL 禁止该棋子再次攻击，直到下一回合
5. IF 目标格子不在攻击范围内，THEN THE Combat_System SHALL 拒绝攻击
6. IF 目标格子没有敌方棋子，THEN THE Combat_System SHALL 拒绝攻击
7. WHEN 攻击发生，THE Combat_System SHALL 发出 attack_performed 信号，携带攻击者、目标、伤害值

---

### 需求 4：回合管理系统

**用户故事：** 作为玩家，我希望游戏有明确的回合流程（玩家回合 → 敌方回合），以便进行策略性决策。

#### 验收标准

1. THE TurnManager SHALL 维护回合状态机，状态包括：玩家回合、敌方回合、回合结束判定
2. WHEN 玩家点击"结束回合"按钮，THE TurnManager SHALL 结束玩家回合并开始敌方回合
3. WHEN 敌方所有棋子完成行动，THE TurnManager SHALL 结束敌方回合并开始新的玩家回合
4. WHEN 新的玩家回合开始，THE TurnManager SHALL 重置所有玩家棋子的行动点（移动和攻击状态）
5. WHEN 新的敌方回合开始，THE TurnManager SHALL 重置所有敌方棋子的行动点
6. THE TurnManager SHALL 记录当前回合数，从第 1 回合开始递增
7. WHEN 回合状态发生变化，THE TurnManager SHALL 发出 turn_changed 信号，携带新状态和当前回合数

---

### 需求 5：地图随机生成系统

**用户故事：** 作为玩家，我希望每局游戏的地图都不同，以便增加游戏的可重玩性。

#### 验收标准

1. THE Map_Generator SHALL 根据给定的宽度、高度和随机种子生成一张战斗地图
2. THE Map_Generator SHALL 生成包含以下地形的地图：陆地、森林、山地、河流
3. WHEN 地图生成完成，THE Map_Generator SHALL 保证地图上存在至少一块连通的可通行区域，面积不少于地图总格子数的 40%
4. THE Map_Generator SHALL 在地图的玩家出生区域（左下角 3×3 范围）生成全部为陆地的格子
5. THE Map_Generator SHALL 在地图的敌方出生区域（右上角 3×3 范围）生成全部为陆地的格子
6. WHEN 使用相同种子调用 Map_Generator，THE Map_Generator SHALL 生成完全相同的地图
7. THE Map_Generator SHALL 支持将生成的地图数据序列化为 JSON 格式并保存到文件
8. THE Map_Generator SHALL 支持从 JSON 文件反序列化并还原地图数据

---

### 需求 6：敌方 AI 系统

**用户故事：** 作为玩家，我希望敌方棋子能自动行动并对我方棋子构成威胁，以便游戏有挑战性。

#### 验收标准

1. WHEN 敌方回合开始，THE AIController SHALL 依次控制每个存活的敌方棋子执行行动
2. THE AIController SHALL 优先移动到距离最近的玩家棋子攻击范围内的格子
3. WHEN 敌方棋子移动后，IF 有玩家棋子在攻击范围内，THEN THE AIController SHALL 对最近的玩家棋子发动攻击
4. WHEN 敌方棋子无法到达任何玩家棋子的攻击范围，THE AIController SHALL 移动到尽可能靠近最近玩家棋子的格子
5. WHEN 所有敌方棋子完成行动，THE AIController SHALL 通知 TurnManager 敌方回合结束

---

### 需求 7：游戏胜负判定

**用户故事：** 作为玩家，我希望游戏有明确的胜利和失败条件，以便知道游戏何时结束。

#### 验收标准

1. WHEN 所有敌方棋子死亡，THE Battle_System SHALL 判定玩家胜利并发出 battle_won 信号
2. WHEN 所有玩家棋子死亡，THE Battle_System SHALL 判定玩家失败并发出 battle_lost 信号
3. WHEN 游戏胜利或失败，THE Battle_System SHALL 显示对应的结果界面（胜利/失败提示）
4. WHEN 游戏结束，THE Battle_System SHALL 停止接受玩家输入和 AI 行动

---

### 需求 8：UI 与信息展示

**用户故事：** 作为玩家，我希望界面能清晰展示当前回合、棋子状态和操作提示，以便做出正确决策。

#### 验收标准

1. THE UI_System SHALL 在屏幕上方显示当前回合数和当前行动方（玩家/敌方）
2. WHEN 玩家选中一个棋子，THE UI_System SHALL 在信息面板中显示该棋子的名称、血量、移动力、攻击力、防御力
3. THE UI_System SHALL 在每个棋子头顶显示血量条，血量条随当前血量实时更新
4. WHEN 棋子已移动但未攻击，THE UI_System SHALL 对该棋子应用半透明效果以区分行动状态
5. WHEN 棋子已完成所有行动，THE UI_System SHALL 对该棋子应用灰色效果以表示行动结束
6. THE UI_System SHALL 提供"结束回合"按钮，仅在玩家回合时可点击

---

### 需求 9：模块化架构

**用户故事：** 作为开发者，我希望各系统模块高内聚低耦合，以便独立开发、测试和扩展。

#### 验收标准

1. THE Architecture SHALL 通过 EventBus（全局信号总线）实现模块间通信，各模块不直接持有其他模块的引用
2. THE Architecture SHALL 将以下系统实现为独立的 GDScript 类：TurnManager、UnitManager、MovementSystem、CombatSystem、AIController、MapGenerator
3. THE Architecture SHALL 使用 Resource 类型（UnitData）定义棋子配置数据，与运行时逻辑分离
4. WHEN 任意单个模块被替换或修改，THE Architecture SHALL 保证其他模块无需修改即可正常运行
5. THE Architecture SHALL 为每个公共方法提供中文注释，说明参数含义和返回值
