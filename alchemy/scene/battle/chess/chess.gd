extends Node2D
class_name Chess
var groundTextures = preload("res://texture/battle/chess/Tilemap_Flat.png")

class Cell:
	# 格子尺寸
	var cell_size:int = 64  
	# 单元格在格子坐标系中的格子坐标
	var cell_grid_position:Vector2i
	# 实际的像素坐标
	var cell_actual_position:Vector2
	# 格子节点挂载
	var cell_node:ColorRect
	# 格子容器,装载各种东西
	var cell_container:Array
	func _init(x:int,y:int):
		cell_node = ColorRect.new()
		cell_node.size = Vector2(cell_size, cell_size)
		cell_node.position = Vector2(x * cell_size, y * cell_size)
		cell_grid_position = Vector2i(x, y)
		cell_actual_position = Vector2(x * cell_size, y * cell_size)
		cell_node.color = Color(0.2, 0.2, 0.2)
		
# 网格是多少个Cell
var grid_size = Vector2i(10, 10)	
var cell_size = 64
var selected_cell = null # 选中的格子
var highlight_lines = []
var grid_cells:Array[Array]=[]
var grid_node:Node2D
var grid_tile_layer:TileMapLayer
func _init(Grid:Node2D,tileLayer:TileMapLayer):
	grid_node = Grid
	# 让地图素材zindex高于背景 但是低于线条
	tileLayer.z_index = 1
	grid_tile_layer = tileLayer
	createCells()
	createLine()
	
func createCells():
	for x in range(grid_size.x):
		var node_row = []
		for y in range(grid_size.y):
			node_row.append(null)
		grid_cells.append(node_row)
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = Cell.new(x,y)
			grid_node.add_child(cell.cell_node)
			grid_cells[x][y] = cell
			
func createLine():
	for x in range(grid_size.x + 1):
		var line = Line2D.new()
		line.add_point(Vector2(x * cell_size, 0))
		line.add_point(Vector2(x * cell_size, grid_size.y * cell_size))
		line.width = 2
		line.default_color = Color(0.5, 0.5, 0.5)
		line.z_index =3
		grid_node.add_child(line)

	for y in range(grid_size.y + 1):
		var line = Line2D.new()
		line.add_point(Vector2(0, y * cell_size))
		line.add_point(Vector2(grid_size.x * cell_size, y * cell_size))
		line.width = 2
		line.z_index =3
		line.default_color = Color(0.5, 0.5, 0.5)
		grid_node.add_child(line)	
		
func get_grid_center_position():
	return Vector2(grid_size.x * cell_size / 2, grid_size.y * cell_size / 2)
	
func use_json_to_create_map(json:Array):
	# 检查 JSON 是否有效
	if json.is_empty():
		push_error("JSON array is empty!")
		return null
	var row_size = json.size()
	var col_size = json[0].size()
	
	# 创建 TileSet
	var tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)
	
	# 创建 TileSetAtlasSource
	var atlas_source = TileSetAtlasSource.new()
	if not is_instance_valid(groundTextures):
		push_error("groundTextures is not a valid Texture2D!")
		return null

	atlas_source.texture = groundTextures
	atlas_source.texture_region_size = Vector2i(64, 64)
	atlas_source.create_tile(Vector2i(1, 1)) # 可根据需要配置瓦片属性
	# 添加源到 TileSet（自动分配 source ID）
	tile_set.add_source(atlas_source)
	
# 确保 grid_tile_layer 已正确初始化
	if not is_instance_valid(grid_tile_layer):
		push_error("grid_tile_layer is not a valid TileMapLayer!")
		return null
	grid_tile_layer.tile_set = tile_set
	
	# 设置瓦片（注意行列顺序）
	for r in range(row_size):
		for c in range(col_size):
			if json[r][c] == 1:
				grid_tile_layer.set_cell(Vector2i(c, r), 0, Vector2i(1, 1))
	
	pass
	
func 添加棋子(piece:Node2D,棋子的棋盘坐标:Vector2i):
	var x = 棋子的棋盘坐标.x
	var y = 棋子的棋盘坐标.y
	(grid_cells[x][y] as Cell).cell_container.push_front(piece)
	piece.global_position = 根据棋子棋盘坐标生成像素坐标(棋子的棋盘坐标)
	grid_node.add_child(piece)
	pass
	
func 根据棋子棋盘坐标生成像素坐标(chessPosition:Vector2i)-> Vector2:
	var cx = chessPosition.x 
	var cy = chessPosition.y
	var cs = cell_size
	if(cx <grid_size.x and cx >=0) and (cy <grid_size.y and cy >=0):
		return Vector2(cx * cs  + cs /2, cy * cs + cs /2 )
	return Vector2.ZERO 


func input(mouse_pos:Vector2):
	var cell_x = int(mouse_pos.x / cell_size)
	var cell_y = int(mouse_pos.y / cell_size)
	if cell_x >= 0 and cell_x < grid_size.x and cell_y >= 0 and cell_y < grid_size.y:
		handle_click_cell(Vector2i(cell_x, cell_y))

var selected_npc;
func handle_click_cell(cell_position: Vector2i):
	var curCell = grid_cells[cell_position.x][cell_position.y] as Cell
	if curCell != null:
		selected_cell = curCell
		# 判断当前选中的格子中是否存在npc
		for i in curCell.cell_container:
			#  TODO 先假设当前选中的cell的容器中所有都是npc 后续会设置一个属性来判断是人物还是建筑
			# 如果当前选中的地块中存在npc则改为选中当前的npc
			# 不存在则判断是否存在选中的npc,如果存在则移动当当前位置
			
			if i:
				#selected_npc = 
				select_npc_in_cell(i,curCell)
				return
			break;
	
	if selected_npc != null:
		if selected_npc.is_valid_move(cell_position):
			move_piece(selected_npc, cell_position)
		clear_selection()

func select_npc_in_cell(npc: Node2D,cell:Cell):
	#clear_selection()
	#selected_cell = cell
	selected_npc = npc
	cell.cell_node.color = Color(0, 1, 0)
	highlight_cell_lines(cell.cell_grid_position)

func move_piece(piece, target: Vector2i):
	var old_pos = piece.pos
	piece.set_piece_position(target)
	for i in (grid_cells[old_pos.x][old_pos.y] as Cell).cell_container:
		# TODO:
		i = null;
	(grid_cells[target.x][target.y] as Cell).cell_container.append(piece)
#
func clear_selection():
	#if selected_cell != null:
	selected_cell.cell_node.color = Color(0.2, 0.2, 0.2)
	clear_highlight_lines()
	selected_cell = null
	selected_npc = null

func highlight_cell_lines(cell: Vector2i):
	var x = cell.x
	var y = cell.y
	var points = [
		[Vector2(x * cell_size, y * cell_size), Vector2((x + 1) * cell_size, y * cell_size)],
		[Vector2(x * cell_size, (y + 1) * cell_size), Vector2((x + 1) * cell_size, (y + 1) * cell_size)],
		[Vector2(x * cell_size, y * cell_size), Vector2(x * cell_size, (y + 1) * cell_size)],
		[Vector2((x + 1) * cell_size, y * cell_size), Vector2((x + 1) * cell_size, (y + 1) * cell_size)]
	]

	for point_pair in points:
		var line = Line2D.new()
		line.add_point(point_pair[0])
		line.add_point(point_pair[1])
		line.width = 4
		line.z_index = 99
		line.default_color = Color(1, 1, 0)
		grid_node.add_child(line)
		highlight_lines.append(line)
#
func clear_highlight_lines():
	for line in highlight_lines:
		line.queue_free()
	highlight_lines.clear()
	#
	#
	#
#func createRandomPosition(count:int):
	#var placed_positions = []
	#for i in count:
		#var pos = Vector2i(randi() % grid_size.x, randi() % grid_size.y)
		#var attempts = 0
		#while pos in placed_positions and attempts < 100:
			#pos = Vector2i(randi() % grid_size.x, randi() % grid_size.y)
			#attempts += 1
			#if attempts >= 100:
				#push_error("Failed to find unique position for piece")
				#continue
		#placed_positions.append(pos)
		#print("Spawning piece at grid position: ", pos)
	#var temp = []
	##temp: 实际位置
	##placed_positions： 棋盘位置
	#for new_pos in placed_positions:
		#var np = Vector2(new_pos.x * cell_size + cell_size / 2, new_pos.y * cell_size + cell_size / 2)
		#temp.append(np)
	#return [placed_positions,temp]
	#
