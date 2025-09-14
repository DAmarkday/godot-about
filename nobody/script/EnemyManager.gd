extends Node

# 存活的敌人的数量
var still_alive_counts  = 0
# 所击杀敌人的数量
var kill_counts = 0

var enemies = []

var mapInstance:Map = null;

func create(mapNode):
	mapInstance= mapNode
	
func getMapInstance():
	return mapInstance
	
func createEnemy(enemyResource:Resource,once_count:int):
	for i in once_count:
		var enemy = enemyResource.instantiate()
		enemies.append(enemy)
		mapInstance.addEntityToViewer(enemy)
		enemy.global_position = getRandomPoint()

#从地图所有地块中随机获取一个地块的中心点 然后转化为全局坐标
func getRandomPoint() -> Vector2:
	if mapInstance == null:
		push_warning("mapInstance is null")
		return Vector2.ZERO

	var mapLandTileMap = mapInstance.getMapLandTileMap()
	if mapLandTileMap == null:
		push_warning("mapLandTileMap is null")
		return Vector2.ZERO

	var valid_tiles = mapLandTileMap.get_used_cells()
	if valid_tiles.is_empty():
		push_warning("No valid tiles found in TileMap")
		return Vector2.ZERO

	# 随机选择一个有效 Tile
	var point = valid_tiles[randi() % valid_tiles.size()]

	# 转换为世界坐标
	var point_local = mapLandTileMap.map_to_local(point)
	var  point_gloabl=mapLandTileMap.to_global(point_local)
	
	return point_gloabl
