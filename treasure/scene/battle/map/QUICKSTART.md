# 快速开始指南

## 5 分钟上手回合制战棋地图系统

### 第一步：配置 TileSet（必须）

1. 在 Godot 编辑器中创建新的 TileSet 资源
2. 添加你的地形图块（陆地、河流、山地等）
3. **重要**：配置 Terrain Sets
   - 右键 TileSet → Add Terrain Set
   - Terrain Set 0: 陆地
   - Terrain Set 1: 河流
4. 为每个图块配置 Terrain peering bits（边缘连接）
5. 保存 TileSet 为 `res://assets/tileset.tres`

### 第二步：设置场景

1. 打开 `MapRoot.tscn`
2. 选中 `TileMapLayer0` 节点
3. 在 Inspector 中设置 `Tile Set` 为你创建的 TileSet
4. 对 `TileMapLayer1` 和 `HighlightLayer` 重复此操作

### 第三步：运行测试

1. 打开 `TestMap.tscn`
2. 按 F5 运行场景
3. 你应该看到自动生成的地图

### 第四步：测试功能

- **左键点击棋子**：显示移动范围（蓝色高亮）
- **左键点击蓝色格子**：移动棋子到该位置
- **按 G 键**：生成新的随机地图
- **按 S 键**：保存当前地图到 `user://test_map.json`
- **按 L 键**：加载保存的地图

## 集成到你的项目

### 方式 1：使用 MapRoot 场景

```gdscript
# 在你的主场景中
var map_root = preload("res://scene/battle/map/MapRoot.tscn").instantiate()
add_child(map_root)

# 生成地图
map_root.generate_new_map(50, 50, 12345)

# 添加棋子
var unit = preload("res://scene/battle/map/Unit.tscn").instantiate()
map_root.add_unit(unit, Vector2i(10, 10))
```

### 方式 2：手动组装

```gdscript
# 创建地图数据
var generator = MapGenerator.new(50, 50)
var map_data = generator.generate_full_map()

# 加载到场景
var loader = MapLoader.new()
loader.layer0 = $TileMapLayer0
loader.layer1 = $TileMapLayer1
loader.load_map(map_data)

# 创建移动计算器
var calculator = MovementRangeCalculator.new(map_data)
```

## 自定义地图生成

### 修改地形分布

编辑 `MapGenerator.gd` 中的 `_noise_to_terrain()` 函数：

```gdscript
func _noise_to_terrain(noise_value: float) -> int:
    if noise_value < -0.5:
        return MapData.TerrainType.RIVER  # 更多河流
    elif noise_value < 0.2:
        return MapData.TerrainType.LAND
    else:
        return MapData.TerrainType.FOREST  # 更多森林
```

### 修改地形成本

编辑 `MapData.gd` 中的 `TERRAIN_COSTS`：

```gdscript
const TERRAIN_COSTS = {
    TerrainType.LAND: 1.0,
    TerrainType.RIVER: 3.0,    # 河流更难通过
    TerrainType.FOREST: 2.0,   # 森林更难通过
    TerrainType.MOUNTAIN: INF
}
```

## 常见问题排查

### 问题：地图不显示

**解决方案**：
1. 检查 TileMapLayer 是否设置了 TileSet
2. 检查 `MapLoader.TERRAIN_TO_ATLAS` 中的坐标是否正确
3. 在 `MapLoader.load_map()` 后添加 `print()` 调试

### 问题：移动范围不显示

**解决方案**：
1. 检查 HighlightLayer 的 TileSet 是否配置
2. 检查 HighlightLayer 的 Z-index 是否为 10
3. 检查 `HIGHLIGHT_ATLAS` 坐标是否正确

### 问题：棋子无法移动

**解决方案**：
1. 检查 `TERRAIN_COSTS` 配置
2. 检查目标格子是否被占据
3. 检查移动力是否足够

## 下一步

- 阅读 `README.md` 了解完整架构
- 查看 `MapGenerator.gd` 学习地图生成算法
- 查看 `MovementRangeCalculator.gd` 学习路径计算
- 扩展 `Unit.gd` 添加更多棋子属性

## 需要帮助？

检查以下文件的注释：
- `MapData.gd` - 数据结构说明
- `MapGenerator.gd` - 生成算法说明
- `MovementRangeCalculator.gd` - 路径计算说明
- `MapRoot.gd` - 场景管理说明
