extends Camera2D

var tileMap:TileMapLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().process_frame
	
	#TODO 感觉后面可以优化一下
	var tilemaps:=get_tree().get_nodes_in_group('tilemap')
	for map in tilemaps:
		if map.name == 'Land':
			tileMap = map
	
	
	set_camera_limits()
	pass # Replace with function body.

func set_camera_limits():
	if not tileMap:
		return
	var used_rect:Rect2i = tileMap.get_used_rect()
	var tile_map_size := tileMap.tile_set.get_tile_size()
	limit_left = used_rect.position.x
	print(used_rect.position,tile_map_size)
	limit_top = used_rect.position.y * tile_map_size.y
	limit_right = (used_rect.position.x + used_rect.size.x) *tile_map_size.x
	limit_bottom = (used_rect.position.y + used_rect.size.y)*tile_map_size.y
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
