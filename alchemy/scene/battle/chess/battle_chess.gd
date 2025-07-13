extends Node2D
@onready var Grid = $Grid
@onready var TileLayer:TileMapLayer = $Grid/TileMapLayer

var gridChess:Chess;
func setup_camera(pointer:Vector2):
	var camera = Camera2D.new()
	camera.position = pointer
	camera.zoom = Vector2(1, 1)
	add_child(camera)
	camera.make_current()

var json = [
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
	[0,1,1,1,1,1,1,1,1,0],
]
func _ready():
	gridChess=Chess.new(Grid,TileLayer)
	setup_camera(gridChess.get_grid_center_position())
	# 使用json生成对应的棋盘地图
	gridChess.use_json_to_create_map(json)
