#class_name PathVisualizer
extends TileMapLayer

const ROT_0   = 0
const ROT_90  = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
const ROT_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
const ROT_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V


# ==================== 箭头显示路径函数 ====================
func show_arrow_path(mouse_cell_pos: Vector2i,cells: Array[Vector2i]):
	
	pass


func draw_path_on_layer(path: Array[Vector2i]):
	clear()
	if path.size() <2:
		return
	print("path is ",path)
	for i in range(1, path.size()):
		var prev = path[i-1]
		var curr = path[i]
		var next = path[i+1] if i+1 < path.size() else null
		print("next is ",prev,curr,next)
		var temp = get_arrow_tile_coords(prev, curr, next)
		var tile_coords= temp[0]
		var alt = temp[1]
		set_cell(curr, 0, tile_coords,alt)   # source_id=0，根据你的 TileSet

# 根据前后格子决定用哪个箭头瓦片
func get_arrow_tile_coords(prev: Vector2i, curr: Vector2i, next: Variant = null) -> Variant:
	var dir_in = curr - prev
	var dir_out = Vector2i.ZERO
	if next is Vector2i:
		dir_out = next - curr
	print("dir_out is ",dir_out)
	# 终点箭头
	if dir_out == Vector2i.ZERO:
		match dir_in:
			Vector2i(1,0):  return [Vector2i(0, 0),ROT_180]  # 右指向终点（自己调整坐标）
			Vector2i(-1,0): return [Vector2i(0, 0),ROT_0] 
			Vector2i(0,1):  return [Vector2i(0, 0),ROT_270] 
			Vector2i(0,-1): return [Vector2i(0, 0),ROT_90] 
	
	# 直线
	if dir_in == dir_out:
		if dir_in.x != 0: return [Vector2i(1, 1),ROT_90]    # 横向直线
		else:             return [Vector2i(1, 1),ROT_0]    # 纵向直线
	
	# 拐弯（4种常见）
	if dir_in == Vector2i(1,0) and dir_out == Vector2i(0,1):  return [Vector2i(1, 0),ROT_0]  # 左转下
	if dir_in == Vector2i(1,0) and dir_out == Vector2i(0,-1): return [Vector2i(1, 0),ROT_90]  # 左转上
	
	if dir_in == Vector2i(-1,0) and dir_out == Vector2i(0,1): return [Vector2i(1, 0),ROT_270]  # 右转下
	if dir_in == Vector2i(-1,0) and dir_out == Vector2i(0,-1):return [Vector2i(1, 0),ROT_180]  # 右转上
	#
	if dir_in == Vector2i(0,-1) and dir_out == Vector2i(-1,0): return [Vector2i(1, 0),ROT_0]  # 下转左
	if dir_in == Vector2i(0,-1) and dir_out == Vector2i(1,0):  return [Vector2i(1, 0),ROT_270]  # 下转右
	##
	if dir_in == Vector2i(0,1) and dir_out == Vector2i(-1,0): return [Vector2i(1, 0),ROT_90]  # 上转左
	if dir_in == Vector2i(0,1) and dir_out == Vector2i(1,0):  return [Vector2i(1, 0),ROT_180]  # 上转右
	
	return [Vector2i(0, 0),ROT_0]  # 默认
