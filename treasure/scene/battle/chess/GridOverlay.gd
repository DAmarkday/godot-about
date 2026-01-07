# GridOverlay.gd
extends Node2D
class_name GridOverlay

var parent_chess: Node  # 引用 Chess_Instance，用于访问数据

func _init(chess_instance: Node):
	parent_chess = chess_instance
	name = "GridOverlay"
	z_index = 10  # 确保在瓦片上面

func _draw():
	if parent_chess == null:
		return
	
	# 从父对象获取数据并绘制
	var h_lines: PackedVector2Array = parent_chess.h_lines
	var v_lines: PackedVector2Array = parent_chess.v_lines
	var grid_color: Color = parent_chess.grid_color
	var line_width: float = parent_chess.line_width
	var highlighted_tile: Vector2i = parent_chess.highlighted_tile
	var highlight_color: Color = parent_chess.highlight_color
	var highlight_width: float = parent_chess.highlight_width
	var tile_layer: TileMapLayer = parent_chess._tile_layer

	# 绘制基础网格线（格子间共享）
	if h_lines.size() > 1:
		draw_multiline(h_lines, grid_color, -line_width)  # 负值：分辨率独立
	
	if v_lines.size() > 1:
		draw_multiline(v_lines, grid_color, -line_width)

	# 绘制高亮格子四条边
	if highlighted_tile.x > -500 and is_instance_valid(tile_layer):
		var center = tile_layer.map_to_local(highlighted_tile)
		var half = tile_layer.tile_set.tile_size / 2.0
		var tl = center - half
		var tr = center + Vector2(half.x, -half.y)
		var br = center + half
		var bl = center + Vector2(-half.x, half.y)

		draw_line(tl, tr, highlight_color, highlight_width)
		draw_line(tr, br, highlight_color, highlight_width)
		draw_line(br, bl, highlight_color, highlight_width)
		draw_line(bl, tl, highlight_color, highlight_width)
