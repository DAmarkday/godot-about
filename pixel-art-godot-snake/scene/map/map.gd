extends Node2D
class_name Map

@onready var LandNode = $Land
signal mapIsReady(width:int,height:int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.map = self
	var limitArr=computedLandNodeSize()
	mapIsReady.emit(limitArr[0],limitArr[1])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func computedLandNodeSize():
	if LandNode:
		# 获取使用的矩形区域（以瓦片为单位）
		var used_rect =LandNode.get_used_rect()
		# 获取瓦片大小（假设使用默认 TileSet）
		var tile_size = LandNode.tile_set.tile_size
		
		# 计算宽度和高度（单位：像素）
		var width_in_tiles = used_rect.size.x
		var height_in_tiles = used_rect.size.y
		var width_in_pixels = width_in_tiles * tile_size.x
		var height_in_pixels = height_in_tiles * tile_size.y
		return [width_in_pixels,height_in_pixels]
		
	return [0,0]
