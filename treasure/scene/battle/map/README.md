# 回合制战棋地图系统

基于 Godot 4.3+ 的多层 TileMapLayer 架构，使用 Dictionary 稀疏存储 + Terrain Sets 自动连接 + AStarGrid2D 路径计算。

## 核心架构

### 场景结构
```
MapRoot (Node2D)
├── TileMapLayer0      # 基础地形层（陆地/河流/虚空）Z-index=0
├── TileMapLayer1      # 建筑/装饰层（山脉/村庄/森林）Z-index=1
├── UnitsContainer     # 所有棋子容器 Z-index=2
└── HighlightLayer     # 高亮层（移动范围/攻击范围）Z-index=10
```

### 核心类

#### 1. MapData
- 稀疏存储地图数据（Dictionary<Vector2i, int>）
- 支持多层（layer0=地形，layer1=建筑）
- 提供移动成本计算、可通行性检查
- 支持 JSON 序列化/反序列化

#### 2. MapGenerator
- 使用 FastNoiseLite 生成程序化地图
- 支持 Cellular Automata 平滑
- 支持模板注入（村庄、起点）
- 支持连通性检查

#### 3. MapLoader
- 将 MapData 加载到 TileMapLayer
- 支持 Terrain Sets 自动边缘连接
- 触发 update_internals() 更新地形

#### 4. MovementRangeCalculator
- 基于 AStarGrid2D 计算移动范围
- 考虑地形成本和障碍物
- 支持路径查找和成本计算

#### 5. HighlightLayer
- 显示移动范围、攻击范围、路径
- 半透明覆盖层（Z-index=10）

## 使用方法

### 1. 配置 TileSet

在 Godot 编辑器中创建 TileSet：

1. **创建 Terrain Sets**
   - Terrain Set 0: 陆地（包含陆地、森林变体）
   - Terrain Set 1: 河流（自动岸边连接）

2. **配置自定义数据层**
   - `move_cost` (float): 移动成本
     - 陆地 = 1.0
     - 河流 = 2.0
     - 山地 = INF
   - `block_movement` (bool): 是否阻挡移动

3. **配置 AnimatedTile**（可选）
   - 河流流动动画
   - 村庄炊烟动画

### 2. 生成地图

```gdscript
# 创建地图生成器
var generator = MapGenerator.new(50, 50, 12345)  # 宽度、高度、种子

# 生成完整地图（带平滑和村庄）
var map_data = generator.generate_full_map(2, 3)  # 平滑次数、村庄数量

# 保存到文件
map_data.save_to_file("user://my_map.json")
```

### 3. 加载地图

```gdscript
# 方式1：从 MapData 加载
var map_loader = MapLoader.new()
map_loader.layer0 = $TileMapLayer0
map_loader.layer1 = $TileMapLayer1
map_loader.load_map(map_data)

# 方式2：从文件加载
map_loader.load_map_from_file("user://my_map.json")

# 方式3：直接生成并加载
var map_data = map_loader.generate_and_load_map(50, 50, 12345)
```

### 4. 计算移动范围

```gdscript
# 创建移动计算器
var calculator = MovementRangeCalculator.new(map_data)

# 计算可移动范围
var start_cell = Vector2i(5, 5)
var max_movement = 5
var occupied_cells: Array[Vector2i] = [Vector2i(10, 10)]  # 被占据的格子
var reachable = calculator.calculate_movement_range(start_cell, max_movement, occupied_cells)

# 显示高亮
highlight_layer.show_movement_range(reachable)
```

### 5. 移动棋子

```gdscript
# 计算路径
var path = calculator.calculate_path(from_cell, to_cell, occupied_cells)

# 使用 Tween 动画移动
var tween = create_tween()
for cell in path:
    var target_pos = layer0.map_to_local(cell)
    tween.tween_property(unit, "position", target_pos, 0.2)
tween.play()
```

## 测试场景

运行 `TestMap.tscn` 测试地图系统：

- **左键点击**：选中棋子 / 移动棋子
- **G 键**：生成新地图
- **S 键**：保存地图到 `user://test_map.json`
- **L 键**：加载地图

## 地形类型配置

在 `MapData.gd` 中配置：

```gdscript
enum TerrainType {
    VOID = 0,      # 虚空（不存储）
    LAND = 1,      # 陆地（成本=1.0）
    RIVER = 2,     # 河流（成本=2.0）
    MOUNTAIN = 3,  # 山地（成本=INF）
    FOREST = 4,    # 森林（成本=1.5）
    VILLAGE = 5    # 村庄（成本=1.0）
}
```

## 关键注意事项

1. **不要把棋子放进 TileMapLayer**（会导致动画卡顿）
2. **虚空格子不要存**（Dictionary 不存 key 即可）
3. **河流、山地边缘必须用 Terrain Sets**（自动处理边缘）
4. **大地图建议分块生成**（>200×200）
5. **生成后记得 `layer.update_internals()`**（触发 Terrain 连接）
6. **JSON 保存用 Dictionary**（不要用满数组）

## 扩展功能

### 添加新地形类型

1. 在 `MapData.TerrainType` 添加枚举
2. 在 `MapData.TERRAIN_COSTS` 配置成本
3. 在 `MapGenerator._noise_to_terrain()` 添加映射
4. 在 `MapLoader.TERRAIN_TO_ATLAS` 配置图块坐标

### 自定义生成算法

继承 `MapGenerator` 并重写 `generate_basic_map()`：

```gdscript
class_name MyMapGenerator extends MapGenerator

func generate_basic_map() -> MapData:
    var map_data = MapData.new(width, height)
    # 你的自定义生成逻辑
    return map_data
```

### 添加战争迷雾

在 `MapRoot` 中添加：

```gdscript
var fog_layer: TileMapLayer
var visible_cells: Dictionary = {}

func update_fog_of_war(unit_positions: Array[Vector2i], vision_range: int) -> void:
    fog_layer.clear()
    for pos in unit_positions:
        for x in range(-vision_range, vision_range + 1):
            for y in range(-vision_range, vision_range + 1):
                var cell = pos + Vector2i(x, y)
                visible_cells[cell] = true
```

## 性能优化

- 大地图使用分块加载（Chunk System）
- 使用 `VisibleOnScreenNotifier2D` 剔除不可见棋子
- 缓存移动范围计算结果
- 使用对象池管理棋子实例

## 常见问题

**Q: 地形边缘不连接？**
A: 确保 TileSet 配置了 Terrain Sets，并调用 `layer.update_internals()`

**Q: 棋子移动卡顿？**
A: 不要把棋子放进 TileMapLayer，使用独立的 Node2D + Tween

**Q: 地图文件太大？**
A: 使用 Dictionary 稀疏存储，不要存虚空格子

**Q: 移动范围计算错误？**
A: 检查 `TERRAIN_COSTS` 配置，确保障碍物成本为 INF

## 参考资源

- [Godot TileMapLayer 文档](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html)
- [AStarGrid2D 文档](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html)
- [Terrain Sets 教程](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html#terrain-sets)
