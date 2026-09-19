# grid_utils.gd
class_name GridUtils
extends RefCounted   # 纯工具类不需要 Node，RefCounted 就够了（甚至可以不写 extends）

## 世界坐标 → 格子坐标（地图坐标）
static func world_to_cell(tilemap_layer: TileMapLayer, world_pos: Vector2) -> Vector2i:
	if not tilemap_layer:
		push_error("GridUtils: tilemap_layer 为空")
		return Vector2i.ZERO
	
	var local_pos = tilemap_layer.to_local(world_pos)  # 先转本地坐标（关键！）
	return tilemap_layer.local_to_map(local_pos)


## 格子坐标 → 世界坐标（地图中心点）
static func cell_to_world(tilemap_layer: TileMapLayer, grid_pos: Vector2i) -> Vector2:
	if not tilemap_layer:
		push_error("GridUtils: tilemap_layer 为空")
		return Vector2.ZERO
	
	var local_pos = tilemap_layer.map_to_local(grid_pos)
	return tilemap_layer.to_global(local_pos)  # 转回世界坐标


## 额外常用函数（战棋里超级实用）
#static func get_tile_center_world(tilemap_layer: TileMapLayer, grid_pos: Vector2i) -> Vector2:
	#return grid_to_world(tilemap_layer, grid_pos)
#
#static func is_valid_grid_pos(tilemap_layer: TileMapLayer, grid_pos: Vector2i) -> bool:
	#return tilemap_layer.get_cell_source_id(0, grid_pos) != -1  # 0 是默认 layer
