extends Node2D
class_name BaseWeapon

@onready var fire_timer = $Timer 
@onready var bullet_point = $BulletPoint

@export var bullets_per_magazine = 30  # 每弹夹子弹数
@export var max_magazine_counts = 5 # 最大弹夹数量
@export var total_bullets_counts = 150  # 武器的总子弹数量
@export var weapon_rof = 0.2  # 射速 射击间隔（秒）
@export var damage = 5
@export var weapon_name = '默认枪械'

const _pre_bullet = preload("res://scene/bullet/BaseBullet.tscn")


@onready var sprite = $AnimatedSprite2D

var current_bullet_count_in_single_magazine = 0 # 在当前弹夹中所有的子弹数量
var current_magazine_counts = 0 # 当前所剩余的弹夹数量


var can_shoot = true

func _on_fire_timer_timeout():
	can_shoot = true

func _ready() -> void:
	fire_timer.wait_time = weapon_rof
	fire_timer.one_shot = true  # 单次触发
	fire_timer.connect("timeout", _on_fire_timer_timeout)

func getCurRotateDeg():
	pass

func shoot(dir:Vector2):
	var instance = _pre_bullet.instantiate()
	instance.global_position = bullet_point.global_position
	instance.dir = global_position.direction_to(dir)
	
	can_shoot = false
	fire_timer.start()
