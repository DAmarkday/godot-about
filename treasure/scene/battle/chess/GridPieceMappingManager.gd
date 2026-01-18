extends Node
#用于将棋子和棋盘联系起来的管理类
class_name GridPieceMappingManager

#棋子棋盘位置映射
class GridPieceMappingPosition:
	var occupancy: Dictionary = {}  # Vector2i -> WeakRef(Unit)
	#新增棋盘棋子映射
	func add_mapping(unit:CharacterBody2D,grid_pos:Vector2i):
		var existing = query_mapping(grid_pos)
		if existing != null:
			push_error("当前grid位置已存在棋子,不可覆盖")
			return existing
		
		occupancy[grid_pos] = weakref(unit)
		print(occupancy[grid_pos],occupancy)
		return unit

	#新增棋盘棋子映射
	func remove_mapping(grid_pos: Vector2i) -> bool:
		if occupancy.has(grid_pos):
			occupancy.erase(grid_pos)
			return true
		return false
		
	func modify_mapping(grid_pos: Vector2i, new_unit: CharacterBody2D) -> bool:
		if occupancy.has(grid_pos):
			occupancy[grid_pos] = weakref(new_unit)
			return true
		return false
		
	func query_mapping(grid_pos:Vector2i)->CharacterBody2D:
		if not occupancy.has(grid_pos):
			return null
		var weak_ref = occupancy[grid_pos] as WeakRef
		if weak_ref == null:
			occupancy.erase(grid_pos)  # 清理已經失效的 weakref
			return null
			
		var piece = weak_ref.get_ref() as CharacterBody2D
		if piece == null or not is_instance_valid(piece):
			occupancy.erase(grid_pos)  # 物件已被釋放，清理
			return null
		return piece
			
	func is_exist_piece_in_current_grid_pos(grid_pos:Vector2i)->bool:
		return query_mapping(grid_pos) != null

var _grid_piece_mapping_position_instance:GridPieceMappingPosition=GridPieceMappingPosition.new()

#piece 棋子
#grid_pos 棋盘坐标
#containerNode 棋子的父节点
#layer 棋子grid坐标转化成全局坐标的参考系
func add_piece(piece: CharacterBody2D, grid_pos: Vector2i,containerNode:Node2D,layer:TileMapLayer,chessboard:Chessboard):
	# 在指定格子添加棋子
	if not chessboard.is_valid_grid_position(grid_pos):
		push_error("无效的棋盘坐标: ", grid_pos)
		return
	var cell = chessboard.use_grid_pos_query_cell(grid_pos)
	if cell == null:
		push_error("目标格子不可用: ", grid_pos)
		return
#		
	#cell.container.push_back(piece)
	piece.global_position = chessboard.grid_to_global_pixel_position(layer,grid_pos)
	_grid_piece_mapping_position_instance.add_mapping(piece,grid_pos)
	containerNode.add_child(piece)
	piece.z_index = 99
	
func move_piece(last_grid_pos: Vector2i,to_grid_pos:Vector2i,layer:TileMapLayer,chessboard:Chessboard):
	var is_exist_piece_in_last_grid_pos=query_piece_in_current_grid_pos(last_grid_pos)
	var is_exist_piece_in_to_grid_pos=query_piece_in_current_grid_pos(to_grid_pos)
	if is_exist_piece_in_last_grid_pos == null:
		push_error("选中的棋子不存在")
		return 	
	if is_exist_piece_in_to_grid_pos != null:
		push_error("新地点已存在棋子")
		return
	var piece=_grid_piece_mapping_position_instance.query_mapping(last_grid_pos)
	_grid_piece_mapping_position_instance.remove_mapping(last_grid_pos)
	_grid_piece_mapping_position_instance.add_mapping(piece,to_grid_pos)
	
	piece.global_position = chessboard.grid_to_global_pixel_position(layer,to_grid_pos)
	return
	
func query_piece_in_current_grid_pos(grid_pos: Vector2i)->CharacterBody2D:
	if TypesTools.is_vector2i(grid_pos)== false:
		push_error("grid_pos 参数错误")
		return 
	if TypesTools.is_null(_grid_piece_mapping_position_instance):
		push_error("当前映射类不存在")
		return 
	var piece= _grid_piece_mapping_position_instance.query_mapping(grid_pos)
	return piece
	
func is_exist_piece_in_current_grid_pos(grid_pos: Vector2i)->bool:
	var piece=query_piece_in_current_grid_pos(grid_pos)
	if TypesTools.is_null(piece):
		return false
	else:
		return true
	
	
