extends Node2D
class_name BaseWeapon

@onready var fire_timer = $Timer 
@onready var bullet_point = $BulletPoint
@onready var anim = $AnimatedSprite2D

@export var bullets_per_magazine = 30  # 每弹夹子弹数
@export var max_magazine_counts = 5 # 最大弹夹数量
@export var total_bullets_counts = 150  # 武器的总子弹数量
@export var weapon_rof = 0.2  # 射速 射击间隔（秒）
@export var damage = 5
@export var weapon_name = '默认枪械'

var _pre_bullet = preload("res://scene/bullet/BaseBullet.tscn")


@onready var sprite = $AnimatedSprite2D

var current_bullet_count_in_single_magazine = 0 # 在当前弹夹中所有的子弹数量
var current_magazine_counts = 0 # 当前所剩余的弹夹数量
var current_nearness_enemy_target = null # 当前贴近的敌人

var can_shoot = true

func _on_fire_timer_timeout():
	can_shoot = true

func _ready() -> void:
	fire_timer.wait_time = weapon_rof
	fire_timer.one_shot = true  # 单次触发
	fire_timer.connect("timeout", _on_fire_timer_timeout)

func getCurRotateDeg():
	pass

func getBollPointPos():
	return bullet_point.global_position

func shoot():
	if can_shoot == false:
		return
	
	can_shoot = false
	anim.play("shoot")
	fire_timer.start()
	
	if current_nearness_enemy_target:
		var instance = _pre_bullet.instantiate()
		instance.handle_hurt(current_nearness_enemy_target)
		return
	
	
	
	var instance = _pre_bullet.instantiate()
	instance.global_position = bullet_point.global_position
	
	# 使用枪械的朝向计算子弹方向
	#var direction = Vector2(cos(anim.global_rotation), sin(anim.global_rotation)).normalized()
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - bullet_point.global_position).normalized()
	instance.dir = direction
	
	# 设置子弹旋转，使长方形朝向与移动方向一致
	instance.rotation = anim.global_rotation
	
	GameManager.getMapInstance().addEntityToBulletViewer(instance)
	
	#await anim.animation_finished


func _on_area_2d_body_entered(body: Node2D) -> void:
	current_nearness_enemy_target = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if current_nearness_enemy_target == body:
		current_nearness_enemy_target = null
