extends Node2D
@onready var grid = $Grid
@onready var tile_layer = $Grid/TileMapLayer

@onready var npc1 = preload("res://scene/battle/chess/charA/char_a.tscn")
@onready var npc2 = preload("res://scene/battle/chess/charC/char_c.tscn")
@onready var npc3 = preload("res://scene/battle/chess/charD/char_d.tscn")
@onready var boss1 = preload("res://scene/battle/chess/charB/char_b.tscn")
@onready var boss2 = preload("res://scene/battle/chess/charE/char_e.tscn")

var grid_chess:Chess;
func setup_camera(pointer:Vector2):
	var camera = Camera2D.new()
	camera.position = pointer
	camera.zoom = Vector2(0.7, 0.7)
	add_child(camera)
	camera.make_current()

var json = [
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,0,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
]

func _ready():
	# 初始化 Chess 对象并传入 JSON 数据
	grid_chess = Chess.new(grid, tile_layer, json)
	# 设置相机，居中显示地图
	setup_camera(grid_chess.get_grid_center_position())
	# 根据 JSON 数据生成地图
	grid_chess.create_map_from_json()
	# 在指定位置添加一个 NPC
	grid_chess.add_piece(npc1.instantiate(), Vector2i(2, 2))
	
	grid_chess.add_piece(npc2.instantiate(), Vector2i(2, 5))
	
	grid_chess.add_piece(npc3.instantiate(), Vector2i(3, 3))
	
	grid_chess.add_piece(boss1.instantiate(), Vector2i(5, 5))
	
	grid_chess.add_piece(boss2.instantiate(), Vector2i(7, 3))
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		grid_chess.handle_input(mouse_pos)
