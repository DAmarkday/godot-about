extends RefCounted
class_name MapGenerator

## 地图生成器 - 使用 FastNoiseLite 生成程序化地图
## 支持噪声生成、Cellular Automata 平滑、模板注入

var noise: FastNoiseLite
var width: int
var height: int
var seed_value: int


func _init(map_width: int = 50, map_height: int = 50, map_seed: int = -1) -> void:
	width = map_width
	height = map_height
	seed_value = map_seed if map_seed >= 0 else randi()
	
	# 初始化噪声生成器
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05  # 控制地形变化频率


## 生成基础地图（噪声 + 阈值映射）
func generate_basic_map() -> MapData:
	var map_data = MapData.new(width, height)
	map_data.seed_value = seed_value
	
	for x in range(width):
		for y in range(height):
			var cell = Vector2i(x, y)
			var noise_value = noise.get_noise_2d(x, y)  # 范围 [-1, 1]
			
			# 阈值映射到地形类型
			var terrain_type = _noise_to_terrain(noise_value)
			map_data.set_terrain(cell, terrain_type)
	
	return map_data


## 噪声值映射到地形类型
func _noise_to_terrain(noise_value: float) -> int:
	if noise_value < -0.4:
		return MapData.TerrainType.RIVER  # 河流
	elif noise_value < -0.1:
		return MapData.TerrainType.LAND   # 陆地
	elif noise_value < 0.3:
		return MapData.TerrainType.FOREST # 森林
	elif noise_value < 0.6:
		return MapData.TerrainType.LAND   # 陆地
	else:
		return MapData.TerrainType.MOUNTAIN  # 山地（建筑层）


## Cellular Automata 平滑（用于洞穴、森林等）
func smooth_with_cellular_automata(map_data: MapData, iterations: int = 3) -> void:
	for _i in range(iterations):
		var new_layer = {}
		
		for cell in map_data.get_all_cells():
			var neighbors = _count_terrain_neighbors(map_data, cell, MapData.TerrainType.MOUNTAIN)
			
			# 规则：如果周围山地>=5，变成山地；<=2，变成陆地
			if neighbors >= 5:
				new_layer[cell] = MapData.TerrainType.MOUNTAIN
			elif neighbors <= 2:
				new_layer[cell] = MapData.TerrainType.LAND
			else:
				new_layer[cell] = map_data.get_terrain(cell)
		
		# 应用新层
		for cell in new_layer.keys():
			map_data.set_terrain(cell, new_layer[cell])


## 统计邻居地形数量
func _count_terrain_neighbors(map_data: MapData, cell: Vector2i, terrain_type: int) -> int:
	var count = 0
	var directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),                   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
	]
	
	for dir in directions:
		var neighbor = cell + dir
		if map_data.is_in_bounds(neighbor) and map_data.get_terrain(neighbor) == terrain_type:
			count += 1
	
	return count


## 注入固定模板（例如村庄、起点）
func inject_template(map_data: MapData, template_pos: Vector2i, template_type: String) -> void:
	match template_type:
		"village":
			_place_village(map_data, template_pos)
		"spawn_point":
			_place_spawn_point(map_data, template_pos)


## 放置村庄（3x3 区域）
func _place_village(map_data: MapData, center: Vector2i) -> void:
	for x in range(-1, 2):
		for y in range(-1, 2):
			var cell = center + Vector2i(x, y)
			if map_data.is_in_bounds(cell):
				map_data.set_terrain(cell, MapData.TerrainType.LAND)
				if x == 0 and y == 0:
					map_data.set_building(cell, MapData.TerrainType.VILLAGE)


## 放置起点（清空周围障碍）
func _place_spawn_point(map_data: MapData, center: Vector2i) -> void:
	for x in range(-2, 3):
		for y in range(-2, 3):
			var cell = center + Vector2i(x, y)
			if map_data.is_in_bounds(cell):
				map_data.set_terrain(cell, MapData.TerrainType.LAND)
				map_data.set_building(cell, 0)  # 清除建筑


## 确保连通性（BFS 检查）
func ensure_connectivity(map_data: MapData) -> void:
	var start_cell = _find_first_walkable(map_data)
	if start_cell == Vector2i(-1, -1):
		return
	
	var visited = {}
	var queue = [start_cell]
	visited[start_cell] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		for dir in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var neighbor = current + dir
			if map_data.is_in_bounds(neighbor) and not visited.has(neighbor):
				if map_data.is_walkable(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
	
	# 将未访问的可走格子连接到主岛（简化：直接变成陆地）
	for cell in map_data.get_all_cells():
		if map_data.is_walkable(cell) and not visited.has(cell):
			map_data.set_terrain(cell, MapData.TerrainType.LAND)


## 查找第一个可走格子
func _find_first_walkable(map_data: MapData) -> Vector2i:
	for cell in map_data.get_all_cells():
		if map_data.is_walkable(cell):
			return cell
	return Vector2i(-1, -1)


## 生成完整地图（带所有后处理）
func generate_full_map(smooth_iterations: int = 2, add_villages: int = 3) -> MapData:
	var map_data = generate_basic_map()
	
	# 平滑地形
	smooth_with_cellular_automata(map_data, smooth_iterations)
	
	# 放置村庄
	for i in range(add_villages):
		var pos = Vector2i(randi() % width, randi() % height)
		inject_template(map_data, pos, "village")
	
	# 放置起点
	inject_template(map_data, Vector2i(5, 5), "spawn_point")
	
	# 确保连通性
	ensure_connectivity(map_data)
	
	return map_data
