extends Node2D
@onready var chess = preload("res://scene/chess/chess/chess.tscn")
@onready var groundTextures = preload("res://texture/Ground/Tilemap_Elevation.png")

@onready var 车 = preload("res://scene/chess/rook/rook.tscn")
@onready var 马 = preload("res://scene/chess/knight/knight.tscn")
@onready var 象 = preload("res://scene/chess/Bishop/bishop.tscn")
func _ready() -> void:
	#生成棋盘
	var chess_instance=chess.instantiate()
	add_child(chess_instance)
	
	chess_instance.gridChess.添加棋子(车.instantiate(),Vector2i(2,2))
	
	var tileSet = TileSet.new()
	# 创建一个 TileSetAtlasSource（用于基于图集的瓦片）
	var atlas_source:TileSetAtlasSource = TileSetAtlasSource.new()
	atlas_source.texture = groundTextures
	# 设置纹理的区域（例如，一个 16x16 的瓦片）
	atlas_source.create_tile(Vector2i(0, 0),Vector2i(64, 64))
	# 将 AtlasSource 添加到 TileSet 中（source ID 为 0）
	tileSet.add_source(atlas_source, 0)
	chess_instance.gridChess.棋盘瓦片添加素材集合(tileSet)

	var x:int = chess_instance.gridChess.grid_size.x
	var y = chess_instance.gridChess.grid_size.y
	for i in range(x):
		for j in range(y):
			chess_instance.gridChess.添加地面(0,Vector2i(x,y),Vector2i(0, 0))
			pass
			#var sp = new Spr
			#chess_instance.gridChess.grid_cells[x][y].cell_ground = 
			#chess_instance.gridChess.grid_node.add_child()
			
			
		#var piece = [车,马,象][randi() % 3]
		#var inst=piece.instantiate()
		#chess_instance.生成棋子(inst,arr[0][index],arr[1][index])
	
	
	#生成棋子
	#var arr=chess_instance.createRandomPosition(3)
	#print(arr)
	## 生成棋子
	#for index in range(0,arr[1].size()):
		#var piece = [车,马,象][randi() % 3]
		#var inst=piece.instantiate()
		#chess_instance.生成棋子(inst,arr[0][index],arr[1][index])
	
	pass
