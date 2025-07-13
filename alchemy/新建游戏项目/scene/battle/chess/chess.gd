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
		cell_node.color = Color(0.2, 0.2, 0.2)
		
# 网格是多少个Cell
var grid_size = Vector2i(10, 10)	
var cell_size = 64
var selected_cell = Vector2i(-1, -1)
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
	
