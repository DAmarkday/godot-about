extends Node2D
class_name PieceTemplate

var pos: Vector2i  # 棋子在棋盘上的格子坐标
var grid_size: Vector2i  # 棋盘大小
var grid_cells: Array  # 棋盘格子状态（从 Chess 类获取）
@onready var labelContainer = $Label
@export var label = ''

func _ready():
	labelContainer.text = label
	update_visual()
	
func initialize(grid: Array, size: Vector2i):
	# 初始化棋子，获取棋盘信息
	grid_cells = grid
	grid_size = size

# 虚函数：子类必须实现
func is_valid_move(target: Vector2i) -> bool:
	# 检查目标格子是否为有效移动位置
	if not is_in_bounds(target):
		return false
	
	# 检查目标格子是否可见（JSON 中为 1）
	var cell = grid_cells[target.x][target.y] as Chess.Cell
	if not cell or not cell.is_visible:
		return false
	
	# 检查目标格子是否已有其他棋子
	if not cell.container.is_empty():
		return false
	
	# 示例移动规则：曼哈顿距离 ≤ 1（上下左右一格）
	var distance = abs(target.x - pos.x) + abs(target.y - pos.y)
	return distance <= 1

# 虚函数：子类实现特定视觉效果
func update_visual():
	pass

func set_piece_position(new_pos: Vector2i):
	# 设置棋子位置，更新像素坐标
	pos = new_pos
	position = Vector2(new_pos.x * 64 + 32, new_pos.y * 64 + 32)  # 格子中心

func is_in_bounds(pos: Vector2i) -> bool:
	# 检查坐标是否在棋盘范围内
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y
	
func get_pos() -> Vector2i:
	# 获取当前棋子位置
	return pos
