extends Node2D

const _player = preload("res://scene/player/Player.tscn")
const _weapon = preload("res://scene/weapon/Pistol.tscn")
const _map = preload("res://scene/map/map.tscn")

const _ghoul = preload("res://scene/enemy/Ghoul.tscn")



var icon:Texture2D = preload("res://texture/crosshair161.png")	

func _ready():
	# 设置鼠标光标
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
	
	
	var map = _map.instantiate()
	add_child(map)
	var player = _player.instantiate()
	map.addEntityToViewer(player)
	
	# 在地图中心生成a
	player.global_position = map.getMapCenterPos()
	var weapon = _weapon.instantiate()
	
	player.set_single_hand_weapon(weapon)
	
	EnemyManager.create(map)
	#var ghoulInstance= _ghoul.instantiate()
	EnemyManager.createEnemy(_ghoul,30)
	
	GameManager.create(player,map)
	
