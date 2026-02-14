extends Node2D

## 测试场景 - 演示地图系统的使用

@onready var map_root: MapRoot = $MapRoot


func _ready() -> void:
	# 等待地图生成完成
	await get_tree().process_frame
	
	# 添加测试棋子
	_spawn_test_units()


## 生成测试棋子
func _spawn_test_units() -> void:
	# 创建玩家棋子
	var player_unit = _create_test_unit("玩家", 0)
	map_root.add_unit(player_unit, Vector2i(5, 5))
	
	# 创建敌人棋子
	var enemy_unit = _create_test_unit("敌人", 1)
	map_root.add_unit(enemy_unit, Vector2i(15, 15))


## 创建测试棋子
func _create_test_unit(unit_name: String, team: int) -> Unit:
	var unit = preload("res://scene/battle/map/Unit.tscn").instantiate()
	unit.unit_name = unit_name
	unit.team = team
	unit.movement_range = 5
	return unit


## 处理输入
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 获取点击的格子
			var mouse_pos = get_global_mouse_position()
			var cell = map_root.get_world_position_cell(mouse_pos)
			
			# 通知地图处理点击
			map_root._on_cell_clicked(cell)
	
	# 按 G 键生成新地图
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		map_root.generate_new_map(30, 30)
		_spawn_test_units()
	
	# 按 S 键保存地图
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		map_root.save_map("user://test_map.json")
	
	# 按 L 键加载地图
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		map_root.load_map("user://test_map.json")
