extends Node2D
class_name Chess
@onready var Grid = $Grid
@onready var TileLayer:TileMapLayer = $Grid/TileMapLayer
class Cell:
	#格子尺寸
	var cell_size:int = 64  
	#单元格在所有格子中的格子坐标
	var cell_grid_position:Vector2i
	#实际的像素坐标
	var cell_actual_position:Vector2
	#建筑
	var cell_building:Node2D
	#地面
	var cell_ground:Node2D
	#是否可以站立角色
	var is_can_stand_up:bool = true
	#是否可以被摧毁
	var is_can_be_destroyed:bool = true
	#是否可以交互
	var is_can_be_interaction:bool = false
	var cell_node:ColorRect
	func _init(x:int,y:int):
		cell_node = ColorRect.new()
		cell_node.size = Vector2(cell_size, cell_size)
		cell_node.position = Vector2(x * cell_size, y * cell_size)
		cell_node.color = Color(0.2, 0.2, 0.2)

class GridChess:
	var grid_size = Vector2i(8, 8)	
	var cell_size = 64
	var selected_cell = Vector2i(-1, -1)
	var highlight_lines = []
	var grid_cells:Array[Array]=[]
	#var grid_cells_nodes
	var grid_node:Node2D
	var grid_tile_layer:TileMapLayer
	func _init(Grid:Node2D,tileLayer:TileMapLayer):
		grid_node = Grid
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
			grid_node.add_child(line)

		for y in range(grid_size.y + 1):
			var line = Line2D.new()
			line.add_point(Vector2(0, y * cell_size))
			line.add_point(Vector2(grid_size.x * cell_size, y * cell_size))
			line.width = 2
			line.default_color = Color(0.5, 0.5, 0.5)
			grid_node.add_child(line)	
			
	func get_grid_center_position():
		return Vector2(grid_size.x * cell_size / 2, grid_size.y * cell_size / 2)
	
	func 添加棋子(piece:Node2D,棋子的棋盘坐标:Vector2i):
		var x = 棋子的棋盘坐标.x
		var y = 棋子的棋盘坐标.y
		(grid_cells[x][y] as Cell).cell_building = piece
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
		
	func 根据像素坐标获取棋盘坐标(像素坐标:Vector2):
		if 像素坐标.x < 0 or 像素坐标.y < 0:
			return Vector2.ZERO
			
		var cell_x = int(像素坐标.x / cell_size)
		var cell_y = int(像素坐标.y / cell_size)
		
		if cell_x >= grid_size.x or cell_y >=grid_size.y:
			return Vector2.ZERO
		
		return Vector2i(cell_x,cell_y)
		
	func 棋盘瓦片添加素材集合(source:TileSet):
		grid_tile_layer.tile_set = source
		return source
	
	func 添加地面(瓦片id:int,棋盘坐标:Vector2i,瓦片坐标:Vector2i):
		grid_tile_layer.set_cell(棋盘坐标,瓦片id,瓦片坐标)
		pass
		

func setup_camera(pointer:Vector2):
	var camera = Camera2D.new()
	camera.position = pointer
	camera.zoom = Vector2(1, 1)
	add_child(camera)
	camera.make_current()

var gridChess:GridChess;
func _ready():
	randomize()
	gridChess=GridChess.new(Grid,TileLayer)
	setup_camera(gridChess.get_grid_center_position())

	#create_visual_grid()
	#
	#setup_camera()
	#Grid.position = Vector2(0, 0)
	#print("Grid position: ", Grid.position)


#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var mouse_pos = get_global_mouse_position()
		#var cell_x = int(mouse_pos.x / cell_size)
		#var cell_y = int(mouse_pos.y / cell_size)
		#if cell_x >= 0 and cell_x < grid_size.x and cell_y >= 0 and cell_y < grid_size.y:
			#handle_click(Vector2i(cell_x, cell_y))

#func handle_click(cell: Vector2i):
	#if selected_piece != null:
		#if selected_piece.is_valid_move(cell):
			#move_piece(selected_piece, cell)
		#clear_selection()
	#elif grid_pieces[cell.x][cell.y] != null:
		#select_piece(cell)

#func select_piece(cell: Vector2i):
	#clear_selection()
	#selected_cell = cell
	#selected_piece = grid_pieces[cell.x][cell.y]
	#grid_nodes[cell.x][cell.y].color = Color(0, 1, 0)
	#highlight_cell_lines(cell)

#func move_piece(piece, target: Vector2i):
	#var old_pos = piece.pos
	#piece.set_piece_position(target)
	#grid_pieces[old_pos.x][old_pos.y] = null
	#grid_pieces[target.x][target.y] = piece
#
#func clear_selection():
	#if selected_cell != Vector2i(-1, -1):
		#grid_nodes[selected_cell.x][selected_cell.y].color = Color(0.2, 0.2, 0.2)
		#clear_highlight_lines()
	#selected_cell = Vector2i(-1, -1)
	#selected_piece = null

#func highlight_cell_lines(cell: Vector2i):
	#var x = cell.x
	#var y = cell.y
	#var points = [
		#[Vector2(x * cell_size, y * cell_size), Vector2((x + 1) * cell_size, y * cell_size)],
		#[Vector2(x * cell_size, (y + 1) * cell_size), Vector2((x + 1) * cell_size, (y + 1) * cell_size)],
		#[Vector2(x * cell_size, y * cell_size), Vector2(x * cell_size, (y + 1) * cell_size)],
		#[Vector2((x + 1) * cell_size, y * cell_size), Vector2((x + 1) * cell_size, (y + 1) * cell_size)]
	#]
#
	#for point_pair in points:
		#var line = Line2D.new()
		#line.add_point(point_pair[0])
		#line.add_point(point_pair[1])
		#line.width = 4
		#line.default_color = Color(1, 1, 0)
		#Grid.add_child(line)
		#highlight_lines.append(line)
#
#func clear_highlight_lines():
	#for line in highlight_lines:
		#line.queue_free()
	#highlight_lines.clear()
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
