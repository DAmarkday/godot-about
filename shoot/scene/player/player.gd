extends Node2D

@onready var base = $Sprite2D
@onready var gun = $AnimatedSprite2D
var target_angle: float = 0.0
var current_angle: float = 0.0
var rotation_speed: float = 2.0  # 旋转速度，控制延迟感

# 子弹预制体
var bullet_scene: PackedScene = preload("res://scene/bullet/bullet.tscn")
@export var weapon_rof = 0.2

func _ready():
	pass
	# 设置炮台位置为屏幕底部居中
	#var screen_size = get_viewport_rect().size
	#turret.position = Vector2(screen_size.x / 2, screen_size.y - 50)  # 距离底部50像素

func shoot():
	# 创建子弹
	var bullet = bullet_scene.instantiate()
	bullet.position = gun.position
	bullet.rotation = gun.rotation
	add_child(bullet)

var current_rof_tick = 0
func _process(delta):
	# 处理炮台旋转
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - position
	target_angle = direction.angle()
	
	# 使用插值实现旋转延迟感
	current_angle = lerp_angle(current_angle, target_angle, rotation_speed * delta)
	gun.rotation = current_angle
	
	# 处理射击
	current_rof_tick +=delta
	if Input.is_action_pressed("shoot") and current_rof_tick >= weapon_rof:
		shoot()
		current_rof_tick=0
