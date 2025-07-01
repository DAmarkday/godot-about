extends Node2D
class_name BaseWeapon

# 子弹
@export var bullet = preload("res://scene/bullet/BaseBullet.tscn")

@export var bullets_per_magazine = 30  # 每弹夹子弹数
@export var max_magazine_counts = 5 # 最大弹夹数量
@export var cur_total_bullets_counts = 150  # 当前子弹数量
@export var weapon_reload_rof= 0.42 # 武器换弹速度,数值越大换弹速度越慢

@export var damage = 5 # 武器伤害
@export var weapon_rof = 0.2  # 武器射击间隔,数值越大 两次射击的间隔越大。
@export var weapon_recoil_rof = 0.2 # 武器后坐力参数
@export var weapon_name = '默认枪械' # 武器显示的文本
# 射击音频
@export var shoot_audio = preload("res://audio/wpn_fire_m4.mp3")

var player:Player


@onready var Sprite = $Sprite2D
@onready var BulletPoint = $BulletPoint
@onready var ShootAudio = $ShootAudio

var current_rof_tick = 0

var current_bullet_count_in_single_magazine = 0 # 在当前弹夹中所有的子弹数量
var current_magazine_counts = 0 # 当前的弹夹数量


func weapon_anim():
	# fire_particles.restart()
	
	var tween = create_tween().set_ease(Tween.EASE_IN)
	tween.tween_property(Sprite,'scale:x',0.7,weapon_recoil_rof / 2)
	tween.tween_property(Sprite,'scale:x',1,weapon_recoil_rof / 2)
	if ShootAudio:
		ShootAudio.play()
	Game.player.cameraOffset(Vector2(-1,2),weapon_recoil_rof)
	pass


func shoot():
	var instance = bullet.instantiate()
	instance.global_position = BulletPoint.global_position
	instance.dir = global_position.direction_to(get_global_mouse_position())
	
	
	# 使用枪械的朝向计算子弹方向
	var direction = Vector2(cos(Sprite.global_rotation), sin(Sprite.global_rotation)).normalized()
	instance.dir = direction
	
	# 可选：设置子弹旋转，使长方形朝向与移动方向一致
	instance.rotation = Sprite.global_rotation
	
	#instance.current_weapon = self 
	get_tree().root.add_child(instance)
	
	#current_bullet_count_in_single_magazine -=1
	weapon_anim()

# Called when the node enters the scene tree for the first time.
func _ready():
	ShootAudio.stream = shoot_audio
	pass # Replace with function body.


func _process(delta):
	# 更新节流计时器
	current_rof_tick +=delta
	if Input.is_action_pressed("fire") and current_rof_tick >= weapon_rof:
			# 计时器归零时执行操作并重置计时器
		shoot()	
		current_rof_tick=0
