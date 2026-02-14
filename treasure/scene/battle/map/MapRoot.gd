extends Node2D
class_name MapRoot

## 地图根节点 - 管理整个地图系统
## 包含多层 TileMapLayer + 棋子容器 + 高亮层

@onready var layer0: TileMapLayer = $TileMapLayer0  # 基础地形层
@onready var layer1: TileMapLayer = $TileMapLayer1  # 建筑/装饰层
@onready var units_container: Node2D = $UnitsContainer  # 棋子容器
@onready var highlight_layer: HighlightLayer = $HighlightLayer  # 高亮层

var map_data: MapData
var map_loader: MapLoader
var movement_calculator: MovementRangeCalculator

# 当前选中的棋子
var selected_unit: Node2D = null
var occupied_cells: Dictionary = {}  # {Vector2i: Unit}


func _ready() -> void:
	# 初始化地图加载器
	map_loader = MapLoader.new()
	map_loader.layer0 = layer0
	map_loader.layer1 = layer1
	
	# 生成并加载地图
	generate_new_map(30, 30)


## 生成新地图
func generate_new_map(width: int = 50, height: int = 50, seed_value: int = -1) -> void:
	map_data = map_loader.generate_and_load_map(width, height, seed_value)
	movement_calculator = MovementRangeCalculator.new(map_data)
	print("地图生成完成！")


## 保存地图到文件
func save_map(file_path: String) -> void:
	if map_data != null:
		map_data.save_to_file(file_path)
		print("地图已保存到: " + file_path)


## 加载地图从文件
func load_map(file_path: String) -> void:
	map_loader.load_map_from_file(file_path)
	map_data = MapData.load_from_file(file_path)
	movement_calculator = MovementRangeCalculator.new(map_data)


## 处理格子点击
func _on_cell_clicked(cell: Vector2i) -> void:
	# 如果点击的是棋子
	if occupied_cells.has(cell):
		_select_unit(occupied_cells[cell], cell)
	# 如果已选中棋子，点击移动范围内的格子
	elif selected_unit != null:
		_move_unit_to(cell)


## 选中棋子
func _select_unit(unit: Node2D, cell: Vector2i) -> void:
	selected_unit = unit
	
	# 获取棋子的移动力（假设棋子有 movement_range 属性）
	var movement_range = unit.get("movement_range") if unit.has_method("get") else 5
	
	# 计算可移动范围
	var occupied_list: Array[Vector2i] = []
	occupied_list.assign(occupied_cells.keys())
	var reachable = movement_calculator.calculate_movement_range(cell, movement_range, occupied_list)
	
	# 显示移动范围
	highlight_layer.show_movement_range(reachable)
	highlight_layer.show_selection(cell)


## 移动棋子到目标格子
func _move_unit_to(target_cell: Vector2i) -> void:
	if selected_unit == null:
		return
	
	# 获取当前位置
	var current_cell = layer0.local_to_map(selected_unit.position)
	
	# 计算路径
	var occupied_list: Array[Vector2i] = []
	occupied_list.assign(occupied_cells.keys())
	var path = movement_calculator.calculate_path(current_cell, target_cell, occupied_list)
	
	if path.is_empty():
		print("无法到达目标位置！")
		return
	
	# 显示路径
	highlight_layer.show_path(path)
	
	# 移动棋子（使用 Tween 动画）
	_animate_unit_movement(selected_unit, path)
	
	# 更新占据信息
	occupied_cells.erase(current_cell)
	occupied_cells[target_cell] = selected_unit
	
	# 取消选中
	selected_unit = null
	await get_tree().create_timer(0.5).timeout
	highlight_layer.clear_highlights()


## 棋子移动动画
func _animate_unit_movement(unit: Node2D, path: Array[Vector2i]) -> void:
	var tween = create_tween()
	
	for cell in path:
		var target_pos = layer0.map_to_local(cell)
		tween.tween_property(unit, "position", target_pos, 0.2)
	
	tween.play()


## 添加棋子到地图
func add_unit(unit: Node2D, cell: Vector2i) -> void:
	units_container.add_child(unit)
	unit.position = layer0.map_to_local(cell)
	occupied_cells[cell] = unit


## 移除棋子
func remove_unit(unit: Node2D) -> void:
	var cell = layer0.local_to_map(unit.position)
	occupied_cells.erase(cell)
	unit.queue_free()


## 获取格子的世界坐标
func get_cell_world_position(cell: Vector2i) -> Vector2:
	return layer0.map_to_local(cell)


## 获取世界坐标对应的格子
func get_world_position_cell(world_pos: Vector2) -> Vector2i:
	return layer0.local_to_map(world_pos)
