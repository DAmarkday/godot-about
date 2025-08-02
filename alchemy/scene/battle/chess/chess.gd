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
var highlight_lines: Array = []  # 高亮线条

func _init(grid: Node2D, tile_layer: TileMapLayer, json: Array):
	grid_node = grid
	self.tile_layer = tile_layer
	json_data = json
	# 从 JSON 数据动态设置网格尺寸
	if json.is_empty() or json[0].is_empty():
		push_error("JSON 数据为空或无效！")
		return
	grid_size = Vector2i(json[0].size(), json.size())
	# 设置 TileMapLayer 的 z_index，高于背景但低于线条
	tile_layer.z_index = 1

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
	atlas_source.create_tile(Vector2i(1, 1))  # 配置默认瓦片
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
	
	# 绘制网格线
	create_grid_lines()

func create_grid_lines():
	# 绘制垂直线
	for x in range(grid_size.x + 1):
		var line = Line2D.new()
		line.add_point(Vector2(x * cell_size, 0))
		line.add_point(Vector2(x * cell_size, grid_size.y * cell_size))
		line.width = 2
		line.default_color = Color(0.5, 0.5, 0.5)
		line.z_index = 3
		grid_node.add_child(line)
	
	# 绘制水平线
	for y in range(grid_size.y + 1):
		var line = Line2D.new()
		line.add_point(Vector2(0, y * cell_size))
		line.add_point(Vector2(grid_size.x * cell_size, y * cell_size))
		line.width = 2
		line.default_color = Color(0.5, 0.5, 0.5)
		line.z_index = 3
		grid_node.add_child(line)

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
	cell.container.push_back(piece)
	piece.global_position = grid_to_pixel_position(grid_pos)
	grid_node.add_child(piece)

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
	
	# 点击空格子，清除选择
	clear_selection()

func select_npc_in_cell(npc: Node2D, cell: Cell):
	# 选中 NPC 并高亮格子
	clear_selection()
	selected_cell = cell
	selected_npc = npc
	if cell.cell_node:
		cell.cell_node.color = Color(0, 1, 0)  # 绿色高亮
	highlight_cell_lines(cell.grid_position)

func move_piece(piece, target: Vector2i):
	# 移动棋子到目标格子
	var old_pos = piece.pos if piece.has_method("get_pos") else Vector2i.ZERO
	piece.set_piece_position(target) if piece.has_method("set_piece_position") else null
	if is_valid_grid_position(old_pos):
		(grid_cells[old_pos.x][old_pos.y] as Cell).container.erase(piece)
	(grid_cells[target.x][target.y] as Cell).container.append(piece)
	piece.global_position = grid_to_pixel_position(target)

func highlight_cell_lines(cell_pos: Vector2i):
	# 高亮选中格子的边框
	var x = cell_pos.x
	var y = cell_pos.y
	var points = [
		[Vector2(x * cell_size, y * cell_size), Vector2((x + 1) * cell_size, y * cell_size)],  # 上
		[Vector2(x * cell_size, (y + 1) * cell_size), Vector2((x + 1) * cell_size, (y + 1) * cell_size)],  # 下
		[Vector2(x * cell_size, y * cell_size), Vector2(x * cell_size, (y + 1) * cell_size)],  # 左
		[Vector2((x + 1) * cell_size, y * cell_size), Vector2((x + 1) * cell_size, (y + 1) * cell_size)]  # 右
	]
	
	for point_pair in points:
		var line = Line2D.new()
		line.add_point(point_pair[0])
		line.add_point(point_pair[1])
		line.width = 4
		line.default_color = Color(1, 1, 0)  # 黄色高亮
		line.z_index = 99
		grid_node.add_child(line)
		highlight_lines.append(line)

func clear_selection():
	# 清除选中状态
	if selected_cell and selected_cell.cell_node:
		selected_cell.cell_node.color = Color(0.2, 0.2, 0.2)
	clear_highlight_lines()
	selected_cell = null
	selected_npc = null

func clear_highlight_lines():
	# 清除高亮线条
	for line in highlight_lines:
		line.queue_free()
	highlight_lines.clear()
