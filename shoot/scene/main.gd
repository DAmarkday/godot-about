extends Node2D

var player: PackedScene = preload("res://scene/player/player.tscn")

# 敌人生成相关
var enemy_scene: PackedScene = preload("res://scene/enemy/enemy.tscn")
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5  # 敌人生成间隔

func _ready():
	var a=player.instantiate()
	add_child(a)
	
	# 设置炮台位置为屏幕底部居中
	var screen_size = get_viewport_rect().size
	a.position = Vector2(screen_size.x / 2, screen_size.y - 50)  # 距离底部50像素
	Game.player_position = a.position
	pass
	

func _process(delta):
	# 处理敌人生成
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	# 在屏幕边缘随机生成敌人
	var spawn_pos = Vector2.ZERO
	var side = randi() % 4
	var screen_size = get_viewport_rect().size
		
	if side == 0:  # 上
		spawn_pos = Vector2(randf_range(0, screen_size.x /2), 0)
	elif side == 1:  # 下
		spawn_pos = Vector2(randf_range(screen_size.x /2, screen_size.x), 0)
	elif side == 2: 
		spawn_pos = Vector2(0,randf_range(0, screen_size.y /2))
	else:
		spawn_pos = Vector2(screen_size.x,randf_range(0, screen_size.y /2))
	
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	add_child(enemy)
