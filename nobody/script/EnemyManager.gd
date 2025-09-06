extends Node

# 存活的敌人的数量
var still_alive_counts  = 0
# 所击杀敌人的数量
var kill_counts = 0

var enemies = []

var mapInstance:Node2D = null;

func create(mapNode):
	mapInstance= mapNode
	

func createEnemy(enemyResource:Resource,once_count:int):
	for i in once_count:
		var enemy = enemyResource.instantiate()
		enemies.append(enemy)
		mapInstance.add_child(enemy)
		enemy.position = getRandomPoint()
		
func getRandomPoint():
	if mapInstance == null:
		return
	
	var mapLandTileMap=mapInstance.getMapLandTileMap()
	var rect = mapLandTileMap.get_used_rect() 
	#var area2D = Game.map.enemy_area as Area2D
	#var coll =area2D.get_node('CollisionShape2D') as CollisionShape2D
	#var rect = coll.shape.get_rect()
	
	var point = Vector2i(randi_range(rect.position.x,rect.position.x+ rect.size.x),randi_range(rect.position.y,rect.size.y + rect.position.y))
	#return rect.position + point 
	var point_2 = mapLandTileMap.map_to_local( point)
	return point_2
