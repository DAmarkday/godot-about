extends Node2D
@onready var grid = $container
@onready var tile_layer = $container/TileMapLayer

@onready var enemy = preload("res://scene/battle/chess/piece/enemy/gebulin/gebulin.tscn")

@onready var npc1 = preload("res://scene/battle/chess/piece/npc/npc.tscn")
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

func _ready():
	# 初始化 Chess 对象并传入 JSON 数据
	grid_chess = Chess_Instance.new(64,grid, tile_layer)
	# 根据 JSON 数据生成地图
	grid_chess.create_map_from_json(json,$container)
	
	grid_chess.set_highlight(Vector2i(2,2))
	
	# 设置相机，居中显示地图
	setup_camera(grid_chess.get_grid_center_position())
	
	grid_chess.add_piece(enemy.instantiate(),Vector2i(5,5))
	
	grid_chess.add_piece(npc1.instantiate(),Vector2i(3,3))
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		grid_chess.handle_input(mouse_pos)
