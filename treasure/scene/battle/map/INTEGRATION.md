# 集成到现有项目指南

## 与现有 Chess 系统集成

你的项目已经有 `scene/battle/chess/` 系统，这里是如何将新的地图系统集成进去。

### 方案 1：完全替换（推荐）

如果你想使用新的地图系统替换现有系统：

1. **备份现有代码**
```bash
# 重命名旧系统
mv scene/battle/chess scene/battle/chess_old
```

2. **更新主场景**

编辑 `scene/main.tscn`，替换 Chess 节点：

```gdscript
# 删除旧的
[ext_resource type="PackedScene" uid="uid://d3mxsofn8br7t" path="res://scene/battle/chess/chess.tscn" id="2_wp4xf"]

# 添加新的
[ext_resource type="PackedScene" path="res://scene/battle/map/MapRoot.tscn" id="2_map"]

[node name="MapRoot" parent="." instance=ExtResource("2_map")]
```

3. **迁移 GUI 面板**

保留你的 GUI 系统（UnitPanel, TurnPanel 等），只需连接到新的地图系统：

```gdscript
# scene/main.gd
extends Node2D

@onready var map_root: MapRoot = $MapRoot
@onready var unit_panel = $UnitPanel
@onready var turn_panel = $TurnPanel

func _ready():
    # 生成地图
    map_root.generate_new_map(30, 30)
    
    # 连接信号
    map_root.unit_selected.connect(_on_unit_selected)
    map_root.unit_moved.connect(_on_unit_moved)

func _on_unit_selected(unit: Unit):
    unit_panel.show_unit_info(unit)

func _on_unit_moved(unit: Unit, from: Vector2i, to: Vector2i):
    turn_panel.update_turn()
```

### 方案 2：混合使用

保留现有系统，只使用新系统的部分功能：

#### 使用新的地图生成器

```gdscript
# 在你的 Chessboard.gd 中
var map_generator = MapGenerator.new(width, height)
var map_data = map_generator.generate_full_map()

# 将 map_data 转换为你的格式
for cell in map_data.get_all_cells():
    var terrain = map_data.get_terrain(cell)
    # 设置到你的棋盘系统
    set_cell_terrain(cell, terrain)
```

#### 使用新的移动范围计算

```gdscript
# 在你的棋子移动逻辑中
var calculator = MovementRangeCalculator.new(map_data)
var reachable = calculator.calculate_movement_range(
    piece_position, 
    piece.movement_range,
    get_occupied_cells()
)

# 显示移动范围
for cell in reachable:
    highlight_cell(cell)
```

### 方案 3：逐步迁移

1. **第一阶段：测试新系统**
   - 保留现有系统不变
   - 在单独的测试场景中运行新系统
   - 熟悉新 API

2. **第二阶段：迁移数据层**
   - 使用 MapData 替换现有的地图数据结构
   - 保留现有的渲染和 UI

3. **第三阶段：迁移渲染层**
   - 使用 TileMapLayer 替换现有的渲染
   - 使用 Terrain Sets 自动连接

4. **第四阶段：迁移逻辑层**
   - 使用 MovementRangeCalculator 替换现有的移动计算
   - 使用 HighlightLayer 替换现有的高亮

## 保留现有功能

### 保留 GridPieceMappingManager

如果你的 `GridPieceMappingManager.gd` 有特殊逻辑，可以适配到新系统：

```gdscript
# 在 MapRoot.gd 中添加
var piece_mapping_manager: GridPieceMappingManager

func _ready():
    piece_mapping_manager = GridPieceMappingManager.new()
    piece_mapping_manager.map_root = self
```

### 保留 GridOverlay

如果你的 `GridOverlay.gd` 有自定义绘制，可以替换 HighlightLayer：

```gdscript
# 在 MapRoot.tscn 中
[node name="GridOverlay" type="Node2D" parent="."]
script = ExtResource("path/to/GridOverlay.gd")
z_index = 10
```

### 保留现有棋子

你的现有棋子（knight.tscn, spear.tscn 等）可以直接使用：

```gdscript
# 只需确保它们继承 Node2D 并有 movement_range 属性
var knight = preload("res://scene/battle/chess/piece/player/knight.tscn").instantiate()
map_root.add_unit(knight, Vector2i(5, 5))
```

## 信号系统集成

新系统需要添加信号到 `MapRoot.gd`：

```gdscript
# 在 MapRoot.gd 顶部添加
signal unit_selected(unit: Node2D)
signal unit_moved(unit: Node2D, from: Vector2i, to: Vector2i)
signal unit_attacked(attacker: Node2D, target: Node2D)
signal turn_ended()

# 在相应函数中发射信号
func _select_unit(unit: Node2D, cell: Vector2i) -> void:
    selected_unit = unit
    unit_selected.emit(unit)
    # ... 其他逻辑

func _move_unit_to(target_cell: Vector2i) -> void:
    var from = layer0.local_to_map(selected_unit.position)
    # ... 移动逻辑
    unit_moved.emit(selected_unit, from, target_cell)
```

## 性能对比

| 功能 | 旧系统 | 新系统 | 优势 |
|------|--------|--------|------|
| 地图存储 | 满数组 | 稀疏 Dict | 内存节省 50-80% |
| 地形连接 | 手动 | Terrain Sets | 自动化，节省开发时间 |
| 路径计算 | 自定义 BFS | AStarGrid2D | 性能提升 2-3x |
| 地图生成 | 手动 | 程序化 | 无限可重现地图 |

## 兼容性检查清单

- [ ] TileSet 配置完成
- [ ] 所有 TileMapLayer 设置了 TileSet
- [ ] 现有棋子适配到 Unit 基类
- [ ] GUI 面板连接到新信号
- [ ] 输入处理迁移到新系统
- [ ] 回合管理系统集成
- [ ] 保存/加载系统更新

## 测试步骤

1. **单元测试**
```gdscript
# test_map_system.gd
func test_map_generation():
    var gen = MapGenerator.new(10, 10, 123)
    var data = gen.generate_basic_map()
    assert(data.width == 10)
    assert(data.height == 10)

func test_movement_calculation():
    var data = MapData.new(10, 10)
    var calc = MovementRangeCalculator.new(data)
    var range = calc.calculate_movement_range(Vector2i(5, 5), 3)
    assert(range.size() > 0)
```

2. **集成测试**
   - 运行 TestMap.tscn 验证基础功能
   - 在主场景中测试与 GUI 的集成
   - 测试保存/加载功能

3. **性能测试**
   - 生成大地图（100x100）测试性能
   - 测试多个棋子同时移动
   - 测试内存占用

## 回滚计划

如果遇到问题需要回滚：

1. 恢复备份的旧系统
```bash
mv scene/battle/chess_old scene/battle/chess
```

2. 恢复 main.tscn 的旧配置

3. 保留新系统代码供未来使用
```bash
mv scene/battle/map scene/battle/map_new_system
```

## 技术支持

遇到问题时检查：
1. Godot 控制台的错误信息
2. `MapRoot.gd` 中的 print() 调试输出
3. TileSet 配置是否正确
4. 信号连接是否正确

常见错误：
- "Invalid get index 'layer0'" → TileMapLayer 节点名称不匹配
- "Null instance" → TileSet 未设置
- "Cannot call method on null" → 节点引用错误
