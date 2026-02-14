extends TileMapLayer
class_name HighlightLayer

## 高亮层 - 用于显示移动范围、攻击范围等
## Z-index 应设置为 10，覆盖在棋子上方

const TILESET_SOURCE_ID = 0

# 高亮类型到 atlas 坐标的映射
enum HighlightType {
	MOVEMENT = 0,  # 移动范围（蓝色半透明）
	ATTACK = 1,    # 攻击范围（红色半透明）
	PATH = 2,      # 移动路径（黄色）
	SELECT = 3     # 选中格子（白色边框）
}

const HIGHLIGHT_ATLAS = {
	HighlightType.MOVEMENT: Vector2i(0, 0),
	HighlightType.ATTACK: Vector2i(1, 0),
	HighlightType.PATH: Vector2i(2, 0),
	HighlightType.SELECT: Vector2i(3, 0)
}


func _ready() -> void:
	# 设置高亮层的 Z-index
	z_index = 10
	modulate = Color(1, 1, 1, 0.6)  # 半透明


## 显示移动范围
func show_movement_range(cells: Array[Vector2i]) -> void:
	clear()
	for cell in cells:
		_set_highlight_cell(cell, HighlightType.MOVEMENT)


## 显示攻击范围
func show_attack_range(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_set_highlight_cell(cell, HighlightType.ATTACK)


## 显示移动路径
func show_path(path: Array[Vector2i]) -> void:
	for cell in path:
		_set_highlight_cell(cell, HighlightType.PATH)


## 显示选中格子
func show_selection(cell: Vector2i) -> void:
	_set_highlight_cell(cell, HighlightType.SELECT)


## 清除所有高亮
func clear_highlights() -> void:
	clear()


## 设置高亮格子
func _set_highlight_cell(cell: Vector2i, highlight_type: HighlightType) -> void:
	var atlas_coords = HIGHLIGHT_ATLAS.get(highlight_type, Vector2i(0, 0))
	set_cell(cell, TILESET_SOURCE_ID, atlas_coords)
