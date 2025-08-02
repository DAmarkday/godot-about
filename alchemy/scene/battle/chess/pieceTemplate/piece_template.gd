extends Node2D
class_name PieceTemplate

var pos: Vector2i  # 棋子在棋盘上的格子坐标
var grid_size: Vector2i  # 棋盘大小
var grid_pieces: Array  # 棋盘上的棋子状态
@onready var labelContainer = $Label
@export var label = ''

func _ready():
	labelContainer.text = label
	update_visual()

# 虚函数：子类必须实现
func is_valid_move(_target: Vector2i) -> bool:
	push_error("is_valid_move must be implemented by subclass")
	return false

# 虚函数：子类实现特定视觉效果
func update_visual():
	pass

func set_piece_position(new_pos: Vector2i):
	pos = new_pos
	position = Vector2(new_pos.x * 64 + 32, new_pos.y * 64 + 32)  # 格子中心

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y
