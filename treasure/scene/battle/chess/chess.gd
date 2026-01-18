extends Node2D

@onready var container = $TileMapLayerContainer
@onready var ground_layer = $TileMapLayerContainer/GroundLayer

@onready var player_unit_container_node = $Units/PlayerUnits
@onready var enemy_unit_container_node = $Units/EnemyUnits
#不受玩家和敌人控制的棋子 比如npc
@onready var other_unit_container_node = $Units/OtherUnits

var chessboard_instance:Chessboard;
var grid_piece_mapping_manager_instance:GridPieceMappingManager

func setup_camera(pointer:Vector2):
	var camera = Camera2D.new()
	camera.global_position = Vector2(pointer.x,pointer.y + 121)
	camera.zoom = Vector2(1, 1)
	add_child(camera)
	# #关键：使用 call_deferred 等待一帧，确保布局完成后再精确居中
	#await get_tree().process_frame
	camera.make_current()

var json = [
	[0,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,0,1,0],
	[0,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,0],
	[1,1,1,1,1,1,1,1,1],
	[1,1,1,1,1,1,1,1,1],
]

#封装外部功能方法
func add_player_unit(piece: CharacterBody2D, grid_pos: Vector2i):
	if not chessboard_instance:
		push_error('当前不存在棋盘')
		return
	if not grid_piece_mapping_manager_instance:
		push_error('当前不存在棋盘映射实例')
		return
	grid_piece_mapping_manager_instance.add_piece(piece,grid_pos,player_unit_container_node,ground_layer,chessboard_instance)
	pass
func add_enemy_unit(piece: CharacterBody2D, grid_pos: Vector2i):
	if not chessboard_instance:
		push_error('当前不存在棋盘')
		return
	if not grid_piece_mapping_manager_instance:
		push_error('当前不存在棋盘映射实例')
		return
	grid_piece_mapping_manager_instance.add_piece(piece,grid_pos,enemy_unit_container_node,ground_layer,chessboard_instance)
	pass
func add_other_unit(piece: CharacterBody2D, grid_pos: Vector2i):
	if not chessboard_instance:
		push_error('当前不存在棋盘')
		return
	if not grid_piece_mapping_manager_instance:
		push_error('当前不存在棋盘映射实例')
		return
	grid_piece_mapping_manager_instance.add_piece(piece,grid_pos,other_unit_container_node,ground_layer,chessboard_instance)
	pass

func init_map():
	# 初始化 Chess 对象并传入 JSON 数据
	chessboard_instance = Chessboard.new(64,container,ground_layer)
	# 根据 JSON 数据生成地图 container 用于新增线条
	chessboard_instance.create_map_from_json(json,container)
	# 创建映射类
	grid_piece_mapping_manager_instance = GridPieceMappingManager.new()

var _current_selected_node_grid_position:Vector2i=Vector2i(-1, -1) # 当前选中的棋子的位置 -1,-1为非法值


	
func _input(event: InputEvent) -> void:
	#print(event)
	if event is InputEventMouseMotion:
		#鼠标移动时高亮对应格子的线条
		var mouse_pos = get_global_mouse_position()
		var grid_pos=chessboard_instance.global_pixel_position_to_grid_position(mouse_pos,ground_layer)
		#print('棋盘坐标是 ',grid_pos)
		if TypesTools.is_null(grid_pos):
			#非法坐标直接排除 清空高亮
			chessboard_instance.clear_grid_line_highlight()
			return
		chessboard_instance.set_grid_line_highlight(grid_pos)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var _grid_pos = chessboard_instance.global_pixel_position_to_grid_position(mouse_pos,ground_layer)
		
		if TypesTools.is_null(_grid_pos):
			#排除掉棋盘外的坐标
			return
		if _current_selected_node_grid_position !=Vector2i(-1,-1):
			#已经选中 只是移动
			var is_exist_piece=grid_piece_mapping_manager_instance.is_exist_piece_in_current_grid_pos(_grid_pos)
			if not is_exist_piece:
				grid_piece_mapping_manager_instance.move_piece(_current_selected_node_grid_position,_grid_pos,ground_layer,chessboard_instance)
				_current_selected_node_grid_position =Vector2i(-1,-1)
			else:
				#高亮当前棋子
				_current_selected_node_grid_position = _grid_pos
				var piece = grid_piece_mapping_manager_instance.query_piece_in_current_grid_pos(_grid_pos)
				hight_light_piece(piece)
			return
			
		#开始选中
		var cur_piece=grid_piece_mapping_manager_instance.query_piece_in_current_grid_pos(_grid_pos)
		if TypesTools.is_null(cur_piece):
			print("当前位置暂无映射的棋子")
			return
			
		_current_selected_node_grid_position = _grid_pos
		#高亮当前棋子
		hight_light_piece(cur_piece)
		
		
		
			
		#pass
		
		#var mouse_pos = get_global_mouse_position()
		#grid_chess.handle_input(mouse_pos)

func hight_light_piece(cur_piece:CharacterBody2D):
	#var all_pieces = get_tree().get_nodes_in_group("pieces")
	#for piece in all_pieces:
	Events.piece_selected.emit(cur_piece)
		
func clear_hight_light_piece(cur_piece:CharacterBody2D):
	#var all_pieces = get_tree().get_nodes_in_group("pieces")
	#for piece in all_pieces:
	Events.piece_deselected.emit(cur_piece)


#测试功能
@onready var boomer = preload("res://scene/battle/chess/piece/enemy/gebulin/boomer.tscn")
@onready var fire = preload("res://scene/battle/chess/piece/enemy/gebulin/fire.tscn")
@onready var knight = preload("res://scene/battle/chess/piece/player/knight.tscn")
@onready var spear = preload("res://scene/battle/chess/piece/player/spear.tscn")
func _ready():
	init_map()
	
	chessboard_instance.set_grid_line_highlight(Vector2i(2,2))
	
	# 设置相机，居中显示地图
	setup_camera(chessboard_instance.get_grid_center_global_position(ground_layer))
	
	add_player_unit(knight.instantiate(),Vector2i(3,3))
	
	add_enemy_unit(boomer.instantiate(),Vector2i(5,5))
	
	add_enemy_unit(fire.instantiate(),Vector2i(6,6))
	
	add_player_unit(spear.instantiate(),Vector2i(2,2))

	
