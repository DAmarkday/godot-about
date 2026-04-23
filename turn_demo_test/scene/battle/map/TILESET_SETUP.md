# TileSet 配置详细指南

## 为什么需要配置 TileSet？

TileSet 是地图系统的核心，它定义了：
- 地形图块的外观
- 地形之间的自动连接（Terrain Sets）
- 移动成本等自定义数据
- 动画效果（AnimatedTile）

## 第一步：创建 TileSet 资源

1. 在 Godot 编辑器中，右键点击 FileSystem
2. 选择 "New Resource"
3. 搜索并选择 "TileSet"
4. 保存为 `res://assets/battle_tileset.tres`

## 第二步：导入图块图片

### 准备图片资源

你需要准备以下图块（推荐 16x16 或 32x32 像素）：

```
assets/tiles/
├── land.png          # 陆地（多个变体）
├── river.png         # 河流（多个方向）
├── forest.png        # 森林
├── mountain.png      # 山地
├── village.png       # 村庄
└── highlight.png     # 高亮（移动范围、攻击范围等）
```

### 导入到 TileSet

1. 双击打开 `battle_tileset.tres`
2. 点击底部的 "+" 按钮
3. 选择 "Atlas"
4. 选择你的图块图片（例如 `land.png`）
5. 设置 Texture Region Size（例如 16x16）

## 第三步：配置 Terrain Sets（关键！）

### 什么是 Terrain Sets？

Terrain Sets 让地形边缘自动连接，例如：
- 河流自动生成岸边
- 森林边缘自动过渡到陆地
- 山地边缘自动生成悬崖

### 配置步骤

1. **创建 Terrain Set 0（陆地系统）**
   - 在 TileSet 编辑器中，点击 "Terrains" 标签
   - 点击 "+" 添加 Terrain Set
   - 命名为 "Land"
   - Mode: Match Corners and Sides

2. **添加 Terrain 0（基础陆地）**
   - 在 Terrain Set 0 下点击 "+"
   - 命名为 "Land"
   - 选择颜色（例如绿色）

3. **添加 Terrain 1（森林）**
   - 再次点击 "+"
   - 命名为 "Forest"
   - 选择颜色（例如深绿色）

4. **创建 Terrain Set 1（河流系统）**
   - 添加新的 Terrain Set
   - 命名为 "River"
   - 添加 Terrain 0 "River"（蓝色）

### 配置 Peering Bits（边缘连接）

对于每个图块：

1. 选中图块
2. 在右侧 "Terrains" 面板中
3. 选择对应的 Terrain Set 和 Terrain
4. 点击图块周围的小方块（peering bits）标记边缘类型

**示例：河流图块**
```
┌─────┐
│ L L │  L = Land (陆地边缘)
│L R L│  R = River (河流中心)
│ L L │
└─────┘
```

## 第四步：配置自定义数据层

### 添加移动成本

1. 在 TileSet 编辑器中，点击 "Custom Data Layers" 标签
2. 点击 "+" 添加新层
3. 配置：
   - Name: `move_cost`
   - Type: Float
   - Default Value: 1.0

4. 为每个图块设置成本：
   - 选中陆地图块 → move_cost = 1.0
   - 选中河流图块 → move_cost = 2.0
   - 选中山地图块 → move_cost = inf（输入 999999）
   - 选中森林图块 → move_cost = 1.5

### 添加阻挡标记

1. 添加新的 Custom Data Layer
2. 配置：
   - Name: `block_movement`
   - Type: Bool
   - Default Value: false

3. 为阻挡图块设置：
   - 山地 → block_movement = true
   - 建筑 → block_movement = true

## 第五步：配置高亮图块

高亮层需要单独的图块：

1. 创建新的 Atlas（使用 `highlight.png`）
2. 添加以下图块：
   - (0, 0): 移动范围（蓝色半透明）
   - (1, 0): 攻击范围（红色半透明）
   - (2, 0): 移动路径（黄色）
   - (3, 0): 选中框（白色边框）

3. 设置 Modulate 为半透明（Alpha = 0.6）

## 第六步：配置动画图块（可选）

### 河流流动动画

1. 准备多帧图片：
   ```
   river_frame_0.png
   river_frame_1.png
   river_frame_2.png
   river_frame_3.png
   ```

2. 在 TileSet 编辑器中：
   - 选中河流图块
   - 在 "Animation" 面板中
   - 点击 "+" 添加帧
   - 设置 Frame Duration（例如 0.2 秒）
   - 添加所有帧

### 村庄炊烟动画

同样的方式添加村庄的动画帧。

## 第七步：应用到场景

### 设置 TileMapLayer

1. 打开 `MapRoot.tscn`
2. 选中 `TileMapLayer0`
3. 在 Inspector 中：
   - Tile Set → 选择 `battle_tileset.tres`
   - Tile Set → Tile Size → 设置为你的图块大小（例如 16x16）

4. 对 `TileMapLayer1` 和 `HighlightLayer` 重复此操作

### 更新 MapLoader 配置

编辑 `MapLoader.gd`，更新 `TERRAIN_TO_ATLAS`：

```gdscript
const TERRAIN_TO_ATLAS = {
    MapData.TerrainType.LAND: Vector2i(0, 0),      # 陆地图块的坐标
    MapData.TerrainType.RIVER: Vector2i(1, 0),     # 河流图块的坐标
    MapData.TerrainType.FOREST: Vector2i(2, 0),    # 森林图块的坐标
    MapData.TerrainType.MOUNTAIN: Vector2i(3, 0),  # 山地图块的坐标
    MapData.TerrainType.VILLAGE: Vector2i(4, 0)    # 村庄图块的坐标
}
```

## 第八步：测试

1. 运行 `TestMap.tscn`
2. 检查：
   - [ ] 地形正确显示
   - [ ] 河流边缘自动连接
   - [ ] 森林边缘平滑过渡
   - [ ] 高亮层正确显示
   - [ ] 动画正常播放

## 常见问题

### 问题：地形边缘不连接

**原因**：Peering Bits 配置错误

**解决方案**：
1. 检查每个图块的 Terrain 设置
2. 确保相邻图块的 peering bits 匹配
3. 调用 `layer.update_internals()` 强制更新

### 问题：图块显示错误

**原因**：Atlas 坐标不匹配

**解决方案**：
1. 在 TileSet 编辑器中查看图块的实际坐标
2. 更新 `TERRAIN_TO_ATLAS` 中的坐标
3. 确保 source_id 正确（通常为 0）

### 问题：移动成本不生效

**原因**：Custom Data Layer 名称不匹配

**解决方案**：
1. 确保 Custom Data Layer 名称为 `move_cost`
2. 检查 `MapData.gd` 中的读取代码：
```gdscript
var tile_data = layer0.get_cell_tile_data(cell)
if tile_data:
    var cost = tile_data.get_custom_data("move_cost")
```

## 高级技巧

### 使用 Alternative Tiles（变体）

为同一地形创建多个视觉变体：

1. 在 TileSet 编辑器中右键点击图块
2. 选择 "Create Alternative Tile"
3. 调整变体的外观（旋转、翻转、颜色）
4. 在代码中随机选择变体：
```gdscript
var alternative = randi() % 3  # 0-2 的随机变体
layer.set_cell(cell, source_id, atlas_coords, alternative)
```

### 使用 Physics Layers（物理层）

如果需要碰撞检测：

1. 在 TileSet 编辑器中添加 Physics Layer
2. 为每个图块绘制碰撞形状
3. 在代码中使用：
```gdscript
var collision = layer.get_cell_tile_data(cell).get_collision_polygon_points(0, 0)
```

### 使用 Navigation Layers（导航层）

如果需要 AI 寻路：

1. 添加 Navigation Layer
2. 为可走图块绘制导航多边形
3. 使用 NavigationServer2D 进行寻路

## 推荐资源

- [Godot TileMap 官方教程](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html)
- [Terrain Sets 视频教程](https://www.youtube.com/results?search_query=godot+4+terrain+sets)
- [免费战棋图块资源](https://itch.io/game-assets/free/tag-tileset)

## 示例 TileSet 配置

如果你没有图块资源，可以使用 Godot 内置的颜色矩形：

```gdscript
# 在 TileSet 编辑器中使用 "Single Tile" 模式
# 创建纯色图块用于测试：
# - 绿色 = 陆地
# - 蓝色 = 河流
# - 灰色 = 山地
# - 深绿 = 森林
```

## 完成检查清单

- [ ] TileSet 资源已创建
- [ ] 图块图片已导入
- [ ] Terrain Sets 已配置
- [ ] Peering Bits 已设置
- [ ] Custom Data Layers 已添加
- [ ] 移动成本已配置
- [ ] 高亮图块已添加
- [ ] TileMapLayer 已设置 TileSet
- [ ] MapLoader 坐标已更新
- [ ] 测试场景运行正常

完成这些步骤后，你的地图系统就可以正常工作了！
