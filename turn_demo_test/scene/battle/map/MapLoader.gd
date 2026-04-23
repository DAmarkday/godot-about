extends Node
class_name MapLoader

## 地图加载器 - 将 MapData 加载到 TileMapLayer
## 负责将 Dictionary 数据渲染到场景中

@export var layer0: TileMapLayer  # 基础地形层
@export var layer1: TileMapLayer  # 建筑/装饰层

# TileSet 中的 source_id（通常为 0）
const TILESET_SOURCE_ID = 0

# 地形类型到 atlas 坐标的映射（需要根据你的 TileSet 配置）
const TERRAIN_TO_ATLAS = {
	MapData.TerrainType.LAND: Vector2i(0, 0),
	MapData.TerrainType.RIVER: Vector2i(1, 0),
	MapData.TerrainType.FOREST: Vector2i(2, 0),
	MapData.TerrainType.MOUNTAIN: Vector2i(3, 0),
	MapData.TerrainType.VILLAGE: Vector2i(4, 0)
}


## 加载地图数据到 TileMapLayer
func load_map(map_data: MapData) -> void:
	if layer0 == null or layer1 == null:
		push_error("MapLoader: TileMapLayer 未设置！")
		return
	
	# 清空现有地图
	layer0.clear()
	layer1.clear()
	
	# 加载 layer0（基础地形）
	for cell in map_data.layer0_data.keys():
		var terrain_type = map_data.layer0_data[cell]
		_set_cell_with_terrain(layer0, cell, terrain_type)
	
	# 加载 layer1（建筑/装饰）
	for cell in map_data.layer1_data.keys():
		var building_type = map_data.layer1_data[cell]
		_set_cell_with_terrain(layer1, cell, building_type)
	
	# 触发 Terrain peering 自动连接
	layer0.update_internals()
	layer1.update_internals()
	
	print("地图加载完成: %d x %d, 种子: %d" % [map_data.width, map_data.height, map_data.seed_value])


## 使用 Terrain Sets 设置格子（推荐方式）
func _set_cell_with_terrain(layer: TileMapLayer, cell: Vector2i, terrain_type: int) -> void:
	# 如果你的 TileSet 配置了 Terrain Sets，使用 set_cells_terrain_connect
	# 这会自动处理边缘连接
	var terrain_set = _get_terrain_set(terrain_type)
	var terrain = _get_terrain_id(terrain_type)
	
	if terrain_set >= 0 and terrain >= 0:
		# 使用 Terrain 自动连接
		layer.set_cells_terrain_connect([cell], terrain_set, terrain, false)
	else:
		# 回退到手动设置（不使用 Terrain）
		var atlas_coords = TERRAIN_TO_ATLAS.get(terrain_type, Vector2i(0, 0))
		layer.set_cell(cell, TILESET_SOURCE_ID, atlas_coords)


## 获取地形对应的 Terrain Set ID
func _get_terrain_set(terrain_type: int) -> int:
	match terrain_type:
		MapData.TerrainType.LAND:
			return 0  # Terrain Set 0: 陆地
		MapData.TerrainType.RIVER:
			return 1  # Terrain Set 1: 河流
		MapData.TerrainType.FOREST:
			return 0  # 森林也属于陆地 Terrain Set
		_:
			return -1  # 不使用 Terrain


## 获取地形对应的 Terrain ID（在 Terrain Set 内的索引）
func _get_terrain_id(terrain_type: int) -> int:
	match terrain_type:
		MapData.TerrainType.LAND:
			return 0
		MapData.TerrainType.RIVER:
			return 0
		MapData.TerrainType.FOREST:
			return 1
		_:
			return -1


## 从文件加载并渲染地图
func load_map_from_file(file_path: String) -> void:
	var map_data = MapData.load_from_file(file_path)
	if map_data != null:
		load_map(map_data)


## 生成并加载新地图
func generate_and_load_map(width: int = 50, height: int = 50, seed_value: int = -1) -> MapData:
	var generator = MapGenerator.new(width, height, seed_value)
	var map_data = generator.generate_full_map()
	load_map(map_data)
	return map_data
