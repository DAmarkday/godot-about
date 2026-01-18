extends Node2D
#棋盘类
#不负责棋子
#只负责棋盘的生成 地形生成
class_name Chessboard

var ground_textures = preload("res://texture/map/Tilemap_Flat.png")

# 格子类，代表地图上的一个单元格
class Cell:
	var cell_size: int   # 格子像素尺寸
	var grid_position: Vector2i  # 格子坐标（棋盘坐标系）
	var actual_position: Vector2  # 像素坐标
	var is_visible: bool  # 是否显示格子
	
	func _init(csize:int,x: int, y: int, visible: bool):
		grid_position = Vector2i(x, y)
		cell_size = csize
		actual_position = Vector2(x * cell_size, y * cell_size)
		is_visible = visible
		
var _tile_map_layer_container: Node2D  # 网格的父节点
var _ground_layer: TileMapLayer  # 瓦片图层
var _grid_cell_size:int
# grid 棋盘整体挂载节点 
func _init(_grid_csize:int,grid: Node2D, tile_layer: TileMapLayer):
	_tile_map_layer_container = grid
	_ground_layer = tile_layer
	_grid_cell_size = _grid_csize
	_ground_layer.z_index = 1
	
var _grid_size: Vector2i  # 网格尺寸，动态从 JSON 获取
var _grid_cells: Array[Array] = []  # 存储所有格子

var _grid_overlay: GridOverlay  # 新增引用      # 专门负责绘制网格线的 Node2D 子节点
func create_map_from_json(json_data:Array,lineNode2DContainer:Node2D):
	# 创建 TileSet
	# 要保证json文件中元素必须>1，并且每个元素的长度都是一样的
	var max_y_length = json_data.size()
	var max_x_length =json_data[0].size()
	var grid_size = Vector2i(max_x_length,max_y_length)
	_grid_size = grid_size
	var tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(_grid_cell_size, _grid_cell_size)
	# 创建 TileSetAtlasSource
	if not is_instance_valid(ground_textures):
		push_error("地面纹理未正确加载！")
		return
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = ground_textures
	atlas_source.texture_region_size = Vector2i(_grid_cell_size, _grid_cell_size)
	# 假设 Tilemap_Flat.png 包含以下瓦片：
	# (1,1): 普通格子（带细网格线，1 像素宽）
	# (2,1): 高亮格子（带加粗边框，4 像素宽，或高亮颜色）
	# (3,1): 棋盘外边框（加粗，4 像素宽）
	atlas_source.create_tile(Vector2i(1, 1))  # 普通格子
	atlas_source.create_tile(Vector2i(2, 1))  # 高亮格子
	atlas_source.create_tile(Vector2i(3, 1))  # 外边框
	tile_set.add_source(atlas_source)
	
	# 设置 TileMapLayer 的 TileSet
	if not is_instance_valid(_ground_layer):
		push_error("TileMapLayer 未正确初始化！")
		return
	_ground_layer.tile_set = tile_set
	
	# 初始化格子数组
	for x in range(grid_size.x):
		var row = []
		for y in range(grid_size.y):
			row.append(null)
		_grid_cells.append(row)
	
	# 根据 JSON 数据创建格子和瓦片
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell_is_visible = json_data[y][x] == 1
			var cell = Cell.new(_grid_cell_size,x, y, cell_is_visible)
			_grid_cells[x][y] = cell
			if cell_is_visible:
				# 设置瓦片
				_ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1))
				
				
	# 创建一个专用于绘制的 Node2D 子节点
	_grid_overlay = GridOverlay.new(self)  # 传入 self 作为 parent_chess
	lineNode2DContainer.add_child(_grid_overlay)
	
	# 创建完地图后更新网格线
	_update_grid_lines()

# 返回网格中心像素坐标
func get_grid_center_global_position(layer:TileMapLayer) -> Vector2:
	var rect: Rect2i = layer.get_used_rect()  # 获取实际使用的 tiles 边界 (position 到 end)
	if not rect.has_area():
		return Vector2.ZERO  # 无 tiles 时返回原点
	
	var center_cell: Vector2i = rect.get_center()  # 中心 cell 坐标 (e.g., (-1, -1) 如果从负开始)
	var local_pos = layer.map_to_local(center_cell)  # 转换为 TileMapLayer 的 local 像素坐标（中心已内置 half cell）
	var global_pos = layer.to_global(local_pos)        # 转成全局
	return global_pos


var h_lines: PackedVector2Array = []
var v_lines: PackedVector2Array = []
var highlighted_tile: Vector2i = Vector2i(-999, -999)
var grid_color: Color = Color(1, 1, 1, 0.2)  # 基础线
var highlight_color: Color = Color(0, 1, 1, 0.8)  # 高亮蓝
var line_width: float = 3.0
var highlight_width: float =1.0
func _update_grid_lines():
	if not _ground_layer: return
	var rect = _ground_layer.get_used_rect()
	var tile_size = _ground_layer.tile_set.tile_size  # 或 rendered_tile_size
	h_lines.clear()
	v_lines.clear()
	# 水平线（格子间共享）
	for y in range(rect.position.y, rect.end.y + 1):
		h_lines.append(Vector2(rect.position.x * tile_size.x, y * tile_size.y))
		h_lines.append(Vector2(rect.end.x * tile_size.x, y * tile_size.y))
	# 垂直线（格子间共享）
	for x in range(rect.position.x, rect.end.x + 1):
		v_lines.append(Vector2(x * tile_size.x, rect.position.y * tile_size.y))
		v_lines.append(Vector2(x * tile_size.x, rect.end.y * tile_size.y))
		
	_grid_overlay.queue_redraw()  # 手动触发绘制！
	
func set_grid_line_highlight(coord: Vector2i):
	highlighted_tile = coord
	_grid_overlay.queue_redraw()  # 手动触发高亮更新

func clear_grid_line_highlight():
	highlighted_tile = Vector2i(-999, -999)
	_grid_overlay.queue_redraw()

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	# 检查棋盘坐标是否有效
	return grid_pos.x >= 0 and grid_pos.x < _grid_size.x and grid_pos.y >= 0 and grid_pos.y < _grid_size.y

func grid_to_global_pixel_position(layer:TileMapLayer,grid_pos: Vector2i) -> Vector2:
	# 将棋盘坐标转换为全局像素坐标（中心点）
	if not is_valid_grid_position(grid_pos):
		return Vector2.ZERO
		
	var local_pos =  layer.map_to_local(grid_pos)
	var global_pos = to_global(local_pos)
	return global_pos

func global_pixel_position_to_grid_position(pixel_pos: Vector2,layer:TileMapLayer) -> Variant:
	# 将像素坐标转换为棋盘坐标
	## floor 用于修复当鼠标不在棋盘上时(-50<一个格子高度) 高亮位置错误的情况
	#var cell_x := int(floor(pixel_pos.x / _grid_cell_size))
	#var cell_y := int(floor(pixel_pos.y / _grid_cell_size))
	#var grid_pos := Vector2i(cell_x, cell_y)
	#print('_grid_cell_size is ',_grid_cell_size)
	#print('pixel_pos is ',pixel_pos)
	#print('grid_pos is ',grid_pos)
	var grid_pos = layer.local_to_map(to_local(pixel_pos))

	if is_valid_grid_position(grid_pos):
		return grid_pos
	else:
		return null   

#通过格子坐标去查询格子信息
func use_grid_pos_query_cell(grid_pos:Vector2i)->Cell:
	if not is_valid_grid_position(grid_pos):
		push_error("无效的棋盘坐标: ", grid_pos)
		return null
	var cell = _grid_cells[grid_pos.x][grid_pos.y] as Cell
	return cell
	

##piece 棋子
##grid_pos 棋盘坐标
##containerNode 棋子的父节点
##layer 棋子grid坐标转化成全局坐标的参考系
#func add_piece(piece: CharacterBody2D, grid_pos: Vector2i,containerNode:Node2D,layer:TileMapLayer):
	## 在指定格子添加棋子
	#if not _is_valid_grid_position(grid_pos):
		#push_error("无效的棋盘坐标: ", grid_pos)
		#return
	#var cell = _grid_cells[grid_pos.x][grid_pos.y] as Cell
	#if not cell.is_visible:
		#push_error("目标格子不可用: ", grid_pos)
		#return
	#if not cell.container.is_empty():
		#push_error("目标格子已有棋子: ", grid_pos)
		#return
	#cell.container.push_back(piece)
	#piece.global_position = _grid_to_global_pixel_position(layer,grid_pos)
	#containerNode.add_child(piece)
	#piece.z_index = 99
		
#func handle_input(mouse_pos: Vector2):
	## 处理鼠标点击，转换为棋盘坐标
	#var cell_x = int(mouse_pos.x / _grid_cell_size)
	#var cell_y = int(mouse_pos.y / _grid_cell_size)
	#if not _is_valid_grid_position(Vector2i(cell_x, cell_y)):
		#return
	#if _current_selected_node:
		#add_piece(_current_selected_node,Vector2i(cell_x, cell_y))
		#_current_selected_node = null
		#
		#return
		#
	#var curCell=_grid_cells[cell_x][cell_y] as Cell
	#set_grid_line_highlight(Vector2i(cell_x, cell_y))
	#if not curCell.container.is_empty():
		#_current_selected_node =  curCell.container[0]
			
			
		
		
		#handle_click_cell(Vector2i(cell_x, cell_y))
		
#func handle_click_cell(cell_pos: Vector2i):
	#var cell = _grid_cells[cell_pos.x][cell_pos.y] as Cell
	#if not cell or not cell.is_visible:
		#return
	#
	## 如果已选中 NPC，尝试移动
	#if selected_npc and selected_npc.has_method("is_valid_move") and selected_npc.is_valid_move(cell_pos):
		#move_piece(selected_npc, cell_pos)
		#clear_selection()
		#return
	#
	## 检查格子中是否有 NPC
	#for item in cell.container:
		#if item:  # 假设容器中的对象为 NPC
			#select_npc_in_cell(item, cell)
			#return
	#
	#clear_selection()
