extends Node2D
class_name Chess

var ground_textures = preload("res://texture/battle/chess/Tilemap_Flat.png")

# 格子类，代表地图上的一个单元格
class Cell:
	var cell_size: int = 64  # 格子像素尺寸
	var grid_position: Vector2i  # 格子坐标（棋盘坐标系）
	var actual_position: Vector2  # 像素坐标
	var cell_node: ColorRect  # 格子背景节点
	var container: Array  # 存储 NPC 或其他对象的容器
	var is_visible: bool  # 是否显示格子
	
	func _init(x: int, y: int, visible: bool):
		grid_position = Vector2i(x, y)
		actual_position = Vector2(x * cell_size, y * cell_size)
		is_visible = visible
		if visible:
			cell_node = ColorRect.new()
			cell_node.size = Vector2(cell_size, cell_size)
			cell_node.position = actual_position
			cell_node.color = Color(0.2, 0.2, 0.2)  # 背景色

var grid_size: Vector2i  # 网格尺寸，动态从 JSON 获取
var cell_size: int = 64  # 格子尺寸
var grid_cells: Array[Array] = []  # 存储所有格子
var grid_node: Node2D  # 网格的父节点
var tile_layer: TileMapLayer  # 瓦片图层
var json_data: Array  # 存储传入的 JSON 数据
var selected_cell: Cell = null  # 当前选中的格子
var selected_npc = null  # 当前选中的 NPC

func _init(grid: Node2D, tile_layer: TileMapLayer, json: Array):
	grid_node = grid
	self.tile_layer = tile_layer
	json_data = json
	# 从 JSON 数据动态设置网格尺寸
	if json.is_empty() or json[0].is_empty():
		push_error("JSON 数据为空或无效！")
		return
	grid_size = Vector2i(json[0].size(), json.size())
	tile_layer.z_index = 1

func adapt_to_resolution():
	var screen_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()
	var zoom = camera.zoom.x if camera else 1.0
	tile_layer.scale = Vector2(1.0 / zoom, 1.0 / zoom)
	# 设置整数缩放因子以避免模糊
	get_tree().root.content_scale_factor = 2.0

func create_map_from_json():
	# 创建 TileSet
	var tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(cell_size, cell_size)
	
	# 创建 TileSetAtlasSource
	if not is_instance_valid(ground_textures):
		push_error("地面纹理未正确加载！")
		return
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = ground_textures
	atlas_source.texture_region_size = Vector2i(cell_size, cell_size)
	# 假设 Tilemap_Flat.png 包含以下瓦片：
	# (1,1): 普通格子（带细网格线，1 像素宽）
	# (2,1): 高亮格子（带加粗边框，4 像素宽，或高亮颜色）
	# (3,1): 棋盘外边框（加粗，4 像素宽）
	atlas_source.create_tile(Vector2i(1, 1))  # 普通格子
	atlas_source.create_tile(Vector2i(2, 1))  # 高亮格子
	atlas_source.create_tile(Vector2i(3, 1))  # 外边框
	tile_set.add_source(atlas_source)
	
	# 设置 TileMapLayer 的 TileSet
	if not is_instance_valid(tile_layer):
		push_error("TileMapLayer 未正确初始化！")
		return
	tile_layer.tile_set = tile_set
	
	# 初始化格子数组
	for x in range(grid_size.x):
		var row = []
		for y in range(grid_size.y):
			row.append(null)
		grid_cells.append(row)
	
	# 根据 JSON 数据创建格子和瓦片
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var is_visible = json_data[y][x] == 1
			var cell = Cell.new(x, y, is_visible)
			grid_cells[x][y] = cell
			if is_visible:
				# 添加背景格子
				grid_node.add_child(cell.cell_node)
				# 设置瓦片
				tile_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1))
	
	# 添加棋盘外边框
	#create_border_tiles()

func create_border_tiles():
	# 绘制加粗外边框（使用专用瓦片）
	for x in range(-1, grid_size.x + 1):
		# 顶部和底部边框
		tile_layer.set_cell(Vector2i(x, -1), 0, Vector2i(3, 1))
		tile_layer.set_cell(Vector2i(x, grid_size.y), 0, Vector2i(3, 1))
	for y in range(-1, grid_size.y + 1):
		# 左侧和右侧边框
		tile_layer.set_cell(Vector2i(-1, y), 0, Vector2i(3, 1))
		tile_layer.set_cell(Vector2i(grid_size.x, y), 0, Vector2i(3, 1))

func get_grid_center_position() -> Vector2:
	# 返回网格中心像素坐标
	return Vector2(grid_size.x * cell_size / 2, grid_size.y * cell_size / 2)

func add_piece(piece: Node2D, grid_pos: Vector2i):
	# 在指定格子添加棋子
	if not is_valid_grid_position(grid_pos):
		push_error("无效的棋盘坐标: ", grid_pos)
		return
	var cell = grid_cells[grid_pos.x][grid_pos.y] as Cell
	if not cell.is_visible:
		push_error("目标格子不可用: ", grid_pos)
		return
	if not cell.container.is_empty():
		push_error("目标格子已有棋子: ", grid_pos)
		return
	cell.container.push_back(piece)
	piece.global_position = grid_to_pixel_position(grid_pos)
	grid_node.add_child(piece)
	# 初始化棋子，传递棋盘信息
	if piece.has_method("initialize"):
		piece.initialize(grid_cells, grid_size)
		piece.set_piece_position(grid_pos)

func grid_to_pixel_position(grid_pos: Vector2i) -> Vector2:
	# 将棋盘坐标转换为像素坐标（中心点）
	if is_valid_grid_position(grid_pos):
		return Vector2(grid_pos.x * cell_size + cell_size / 2, grid_pos.y * cell_size + cell_size / 2)
	return Vector2.ZERO

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	# 检查棋盘坐标是否有效
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y

func handle_input(mouse_pos: Vector2):
	# 处理鼠标点击，转换为棋盘坐标
	var cell_x = int(mouse_pos.x / cell_size)
	var cell_y = int(mouse_pos.y / cell_size)
	if is_valid_grid_position(Vector2i(cell_x, cell_y)):
		handle_click_cell(Vector2i(cell_x, cell_y))

func handle_click_cell(cell_pos: Vector2i):
	var cell = grid_cells[cell_pos.x][cell_pos.y] as Cell
	if not cell or not cell.is_visible:
		return
	
	# 如果已选中 NPC，尝试移动
	if selected_npc and selected_npc.has_method("is_valid_move") and selected_npc.is_valid_move(cell_pos):
		move_piece(selected_npc, cell_pos)
		clear_selection()
		return
	
	# 检查格子中是否有 NPC
	for item in cell.container:
		if item:  # 假设容器中的对象为 NPC
			select_npc_in_cell(item, cell)
			return
	
	clear_selection()

func select_npc_in_cell(npc: Node2D, cell: Cell):
	clear_selection()
	selected_cell = cell
	selected_npc = npc
	# 使用高亮瓦片
	tile_layer.set_cell(cell.grid_position, 0, Vector2i(2, 1))
	highlight_move_range(npc)

func move_piece(piece, target: Vector2i):
	# 移动棋子到目标格子
	var old_pos = piece.get_pos() if piece.has_method("get_pos") else Vector2i.ZERO
	if is_valid_grid_position(old_pos):
		var old_cell = grid_cells[old_pos.x][old_pos.y] as Cell
		if old_cell.container.has(piece):
			old_cell.container.erase(piece)
			# 恢复普通瓦片
			tile_layer.set_cell(old_cell.grid_position, 0, Vector2i(1, 1))
		else:
			push_warning("棋子不在旧格子的容器中: ", old_pos)
	
	var target_cell = grid_cells[target.x][target.y] as Cell
	if not target_cell.container.is_empty():
		if target_cell.container[0] == piece:
			target_cell.container.erase(piece)  # 清空目标格子中的自身引用
		else:
			push_error("目标格子已有其他棋子: ", target)
			return
	
	target_cell.container.append(piece)
	piece.set_piece_position(target) if piece.has_method("set_piece_position") else null
	piece.global_position = grid_to_pixel_position(target)
	# 设置高亮瓦片
	tile_layer.set_cell(target_cell.grid_position, 0, Vector2i(2, 1))

func clear_selection():
	if selected_cell:
		# 恢复普通瓦片
		tile_layer.set_cell(selected_cell.grid_position, 0, Vector2i(1, 1))
	clear_move_range_highlights()
	selected_cell = null
	selected_npc = null

var move_range_highlights: Array = []
func get_move_range(piece: Node2D) -> Array[Vector2i]:
	# 获取棋子的可移动范围
	var move_range: Array[Vector2i] = []
	if not piece.has_method("is_valid_move"):
		return move_range
	
	var current_pos = piece.get_pos() if piece.has_method("get_pos") else Vector2i.ZERO
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var target = Vector2i(x, y)
			if piece.is_valid_move(target):
				move_range.append(target)
	return move_range

func highlight_move_range(piece: Node2D):
	# 高亮显示可移动范围
	clear_move_range_highlights()
	var move_range = get_move_range(piece)
	for pos in move_range:
		var cell = grid_cells[pos.x][pos.y] as Cell
		if cell and cell.is_visible:
			# 使用高亮瓦片表示移动范围
			tile_layer.set_cell(pos, 0, Vector2i(2, 1))
			move_range_highlights.append(pos)

func clear_move_range_highlights():
	for pos in move_range_highlights:
		var cell = grid_cells[pos.x][pos.y] as Cell
		if cell and cell.is_visible:
			# 恢复普通瓦片
			tile_layer.set_cell(pos, 0, Vector2i(1, 1))
	move_range_highlights.clear()
