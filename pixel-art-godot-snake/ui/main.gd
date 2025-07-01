extends Node2D
var _map = preload("res://scene/map/Map.tscn")
var _snake = preload("res://scene/enemy/snake/Snake.tscn")

const _player = preload("res://scene/player/Player.tscn")

# Called when the node enters the scene tree for the first time.

var _defaultWeapon = preload("res://scene/weapon/BaseWeapon.tscn")
var _village = preload("res://scene/building/house/village.tscn")
#var _man = preload("res://scene/npc/man.tscn")

func _ready() -> void:
	# 初始化地图
	var mapNode=_map.instantiate()
	var snakeNode=_snake.instantiate()
	var instance = _player.instantiate()
	#var npc = _man.instantiate()
	
	mapNode.connect('mapIsReady',func (w,h):
		# 设置贪吃蛇活动范围和食物生成范围
		snakeNode.setCurActiveRange(w,h)
		add_child(snakeNode)
		
		add_child(instance)
		# 规范主角摄像机范围
		instance.limitPlayerCamera(0,w,h,0)
		instance.position = Vector2(320,160)
		#挂载武器
		var wNode=_defaultWeapon.instantiate()
		Game.player.weapon_node.add_child(wNode)
		
		
		# 生成房屋
		#const margin =10
		#for i in range(0,10):
			#var village = _village.instantiate()
			#village.position = Vector2(randf_range(margin*i, w - (margin*i)),
			#randf_range(margin*i,h - (margin*i)))
			#add_child(village)
			#print(village.position)
		
	)
	
	add_child(mapNode)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
