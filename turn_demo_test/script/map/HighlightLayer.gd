class_name HighlightLayer extends Node2D

## 高亮层：使用 _draw() 绘制移动/攻击范围的半透明矩形
## 不依赖 TileSet，直接用像素坐标绘制，更灵活
## 需要放在地图上方（z_index 较高）

# 格子大小（像素），需要与地图格子大小一致
@export var cell_size: int = 64

# 移动范围高亮颜色（蓝色半透明）
const MOVE_COLOR = Color(0.2, 0.5, 1.0, 0.4)

# 攻击范围高亮颜色（红色半透明）
const ATTACK_COLOR = Color(1.0, 0.2, 0.2, 0.4)

# 当前显示的移动范围格子列表
var _move_cells: Array[Vector2i] = []

# 当前显示的攻击范围格子列表
var _attack_cells: Array[Vector2i] = []


## 显示移动范围高亮（蓝色半透明）
## cells: 要高亮的格子坐标列表
func show_movement_range(cells: Array[Vector2i]) -> void:
	_move_cells = cells
	queue_redraw()


## 显示攻击范围高亮（红色半透明）
## cells: 要高亮的格子坐标列表
func show_attack_range(cells: Array[Vector2i]) -> void:
	_attack_cells = cells
	queue_redraw()


## 清除所有高亮
func clear_highlights() -> void:
	_move_cells = []
	_attack_cells = []
	queue_redraw()


## 绘制高亮（由 Godot 自动调用）
func _draw() -> void:
	var size := Vector2(cell_size, cell_size)

	# 绘制移动范围（蓝色）
	for cell in _move_cells:
		var pos := Vector2(cell.x * cell_size, cell.y * cell_size)
		draw_rect(Rect2(pos, size), MOVE_COLOR)

	# 绘制攻击范围（红色）
	for cell in _attack_cells:
		var pos := Vector2(cell.x * cell_size, cell.y * cell_size)
		draw_rect(Rect2(pos, size), ATTACK_COLOR)
