extends RefCounted
class_name MapData

## 地图数据管理类 - 使用稀疏 Dictionary 存储
## key: Vector2i(x, y)
## value: 地形类型 int (1=陆地, 2=河流, 3=山地等)

# 地形类型常量
enum TerrainType {
	VOID = 0,      # 虚空/不可达（不存储在 Dict 中）
	LAND = 1,      # 陆地
	RIVER = 2,     # 河流
	MOUNTAIN = 3,  # 山地
	FOREST = 4,    # 森林
	VILLAGE = 5    # 村庄
}

# 地形移动成本配置
const TERRAIN_COSTS = {
	TerrainType.LAND: 1.0,
	TerrainType.RIVER: 2.0,
	TerrainType.MOUNTAIN: INF,  # 不可通行
	TerrainType.FOREST: 1.5,
	TerrainType.VILLAGE: 1.0
}

# 地图尺寸
var width: int = 0
var height: int = 0

# 稀疏存储 - 每层独立
var layer0_data: Dictionary = {}  # 基础地形层
var layer1_data: Dictionary = {}  # 建筑/装饰层

# 生成种子（用于可重现地图）
var seed_value: int = 0


func _init(map_width: int = 50, map_height: int = 50) -> void:
	width = map_width
	height = map_height


## 设置基础地形
func set_terrain(cell: Vector2i, terrain_type: int) -> void:
	if terrain_type == TerrainType.VOID:
		layer0_data.erase(cell)  # 虚空不存储
	else:
		layer0_data[cell] = terrain_type


## 设置建筑/装饰
func set_building(cell: Vector2i, building_type: int) -> void:
	if building_type == 0:
		layer1_data.erase(cell)
	else:
		layer1_data[cell] = building_type


## 获取地形类型
func get_terrain(cell: Vector2i) -> int:
	return layer0_data.get(cell, TerrainType.VOID)


## 获取建筑类型
func get_building(cell: Vector2i) -> int:
	return layer1_data.get(cell, 0)


## 获取移动成本（综合地形和建筑）
func get_move_cost(cell: Vector2i) -> float:
	var terrain = get_terrain(cell)
	if terrain == TerrainType.VOID:
		return INF
	
	var building = get_building(cell)
	if building == TerrainType.MOUNTAIN:  # 建筑层的山脉阻挡
		return INF
	
	return TERRAIN_COSTS.get(terrain, 1.0)


## 检查格子是否可通行
func is_walkable(cell: Vector2i) -> bool:
	return get_move_cost(cell) < INF


## 检查格子是否在地图范围内
func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


## 获取所有有效格子（用于遍历）
func get_all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(layer0_data.keys())
	return cells


## 保存为 JSON
func to_json() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"seed": seed_value,
		"layer0": _dict_to_array(layer0_data),
		"layer1": _dict_to_array(layer1_data)
	}


## 从 JSON 加载
func from_json(data: Dictionary) -> void:
	width = data.get("width", 50)
	height = data.get("height", 50)
	seed_value = data.get("seed", 0)
	layer0_data = _array_to_dict(data.get("layer0", []))
	layer1_data = _array_to_dict(data.get("layer1", []))


## 辅助：Dictionary 转数组（用于 JSON 序列化）
func _dict_to_array(dict: Dictionary) -> Array:
	var arr: Array = []
	for cell in dict.keys():
		arr.append({"x": cell.x, "y": cell.y, "v": dict[cell]})
	return arr


## 辅助：数组转 Dictionary
func _array_to_dict(arr: Array) -> Dictionary:
	var dict: Dictionary = {}
	for item in arr:
		dict[Vector2i(item.x, item.y)] = item.v
	return dict


## 保存到文件
func save_to_file(file_path: String) -> Error:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(to_json(), "\t"))
	file.close()
	return OK


## 从文件加载
static func load_from_file(file_path: String) -> MapData:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开地图文件: " + file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("JSON 解析失败: " + json.get_error_message())
		return null
	
	var map_data = MapData.new()
	map_data.from_json(json.data)
	return map_data
