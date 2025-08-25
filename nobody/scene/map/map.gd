extends Node2D

const _player = preload("res://scene/player/Player.tscn")

@onready var MapLandNode:TileMapLayer = $Land

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
	

func _process(delta):
	pass
