extends Node2D

const _player = preload("res://scene/player/Player.tscn")

@onready var MapLandNode:TileMapLayer = $Land

var icon:Texture2D = preload("res://texture/crosshair161.png")


func getMapCenterPos():
	var used_rect:Rect2i = MapLandNode.get_used_rect()
	var tile_map_size := MapLandNode.tile_set.get_tile_size()
	print(used_rect.position,tile_map_size)
	
	var width = (used_rect.size.x) *tile_map_size.x
	var height = (used_rect.size.y)*tile_map_size.y
	var centerPos = Vector2( round(width /2),round(height/2))
	return centerPos
	

func _ready():
	var instance = _player.instantiate()
	
	# 在地图中心生成
	instance.global_position = getMapCenterPos()
	add_child(instance)
	
	# 获取原始图标的尺寸
	var original_size = icon.get_size()
	# 创建一个新的 Image 来调整大小
	var image = icon.get_image()
	image.resize(original_size.x / 2, original_size.y / 2, Image.INTERPOLATE_BILINEAR)

	# 将调整后的 Image 转换为 Texture2D
	var resized_texture = ImageTexture.create_from_image(image)

	# 设置自定义鼠标光标
	# hotspot 是光标的点击点（通常设为图标中心或左上角，视需求调整）
	var hotspot = Vector2(original_size.x / 4, original_size.y / 4) # 居中 hotspot
	DisplayServer.cursor_set_custom_image(resized_texture, DisplayServer.CURSOR_ARROW, hotspot)

func _process(delta):
	pass
