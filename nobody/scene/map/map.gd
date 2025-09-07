extends Node2D
class_name Map
@onready var MapLandNode:TileMapLayer = $Viewer/Land
@onready var Viewer:Node2D = $Viewer
@onready var BulletViewer:Node2D = $BulletViewer

func getMapCenterPos():
	if MapLandNode ==null:
		return
	var used_rect:Rect2i = MapLandNode.get_used_rect()
	var tile_map_size := MapLandNode.tile_set.get_tile_size()
	print(used_rect.position,tile_map_size)
	
	var width = (used_rect.size.x) *tile_map_size.x
	var height = (used_rect.size.y)*tile_map_size.y
	var centerPos = Vector2( round(width /2),round(height/2))
	return centerPos

func getMapLandTileMap():
	return MapLandNode


func addEntityToViewer(entity:Node2D):
	Viewer.add_child(entity)
	pass
	
func addEntityToBulletViewer(entity:Node2D):
	BulletViewer.add_child(entity)
	pass
