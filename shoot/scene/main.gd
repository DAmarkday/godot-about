extends Node2D

# 游戏主场景脚本

# 玩家炮台
class_name PlayerTurret
var turret: Sprite2D
var target_angle: float = 0.0
var current_angle: float = 0.0
var rotation_speed: float = 2.0  # 旋转速度，控制延迟感

# 子弹预制体
var bullet_scene: PackedScene = preload("res://scene/bullet.tscn")

# 敌人生成相关
var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5  # 敌人生成间隔

func _ready():
	# 初始化玩家炮台
	turret = $Turret
	turret.position = Vector2(960, 540)  # 屏幕中心
	# 设置炮台为1x1像素白色方块
	turret.texture = preload("res://icon.svg")

func _process(delta):
	# 处理炮台旋转
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - turret.position
	target_angle = direction.angle()
	
	# 使用插值实现旋转延迟感
	current_angle = lerp_angle(current_angle, target_angle, rotation_speed * delta)
	turret.rotation = current_angle
	
	# 处理射击
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	# 处理敌人生成
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0

func shoot():
	# 创建子弹
	var bullet = bullet_scene.instantiate()
	bullet.position = turret.position
	bullet.rotation = turret.rotation
	add_child(bullet)

func spawn_enemy():
	# 在屏幕边缘随机生成敌人
	var spawn_pos = Vector2.ZERO
	var side = randi() % 4
	var screen_size = get_viewport_rect().size
	
	if side == 0:  # 上
		spawn_pos = Vector2(randf_range(0, screen_size.x), 0)
	elif side == 1:  # 下
		spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y)
	elif side == 2:  # 左
		spawn_pos = Vector2(0, randf_range(0, screen_size.y))
	else:  # 右
		spawn_pos = Vector2(screen_size.x, randf_range(0, screen_size.y))
	
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	add_child(enemy)
