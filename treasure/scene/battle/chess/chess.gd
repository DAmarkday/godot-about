extends Node2D
@onready var container = $TileMapLayerContainer
@onready var ground_layer = $TileMapLayerContainer/GroundLayer

@onready var player_unit_container_node = $Units/PlayerUnits
@onready var enemy_unit_container_node = $Units/EnemyUnits
#不受玩家和敌人控制的棋子 比如npc
@onready var other_unit_container_node = $Units/OtherUnits

var grid_chess:Chess_Instance;

func setup_camera(pointer:Vector2):
	var camera = Camera2D.new()
	camera.position = pointer
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
	grid_chess.add_piece(piece,grid_pos,player_unit_container_node)
	pass
func add_enemy_unit(piece: CharacterBody2D, grid_pos: Vector2i):
	grid_chess.add_piece(piece,grid_pos,enemy_unit_container_node)
	pass
func add_other_unit(piece: CharacterBody2D, grid_pos: Vector2i):
	grid_chess.add_piece(piece,grid_pos,other_unit_container_node)
	pass

func init_map():
	# 初始化 Chess 对象并传入 JSON 数据
	grid_chess = Chess_Instance.new(64,container,ground_layer)
	# 根据 JSON 数据生成地图 container 用于新增线条
	grid_chess.create_map_from_json(json,container)
	grid_chess.set_grid_line_highlight(Vector2i(2,2))
	

	
func _input(event: InputEvent) -> void:
	#print(event)
	if event is InputEventMouseMotion:
		#鼠标移动时高亮对应格子的线条
		var mouse_pos = get_global_mouse_position()
		var grid_pos=grid_chess.pixel_to_grid_position(mouse_pos)
		#print('棋盘坐标是 ',grid_pos)
		if grid_pos == null:
			#非法坐标直接排除 清空高亮
			grid_chess.clear_grid_line_highlight()
			return
		grid_chess.set_grid_line_highlight(grid_pos)
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var mouse_pos = get_global_mouse_position()
		#grid_chess.handle_input(mouse_pos)



#测试功能
@onready var enemy = preload("res://scene/battle/chess/piece/enemy/gebulin/gebulin.tscn")
@onready var npc1 = preload("res://scene/battle/chess/piece/npc/npc.tscn")
func _ready():
	init_map()
	
	# 设置相机，居中显示地图
	setup_camera(grid_chess.get_grid_center_position())
	
	add_player_unit(npc1.instantiate(),Vector2i(3,3))
	
	add_enemy_unit(enemy.instantiate(),Vector2i(5,5))

	
