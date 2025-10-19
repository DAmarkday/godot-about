extends Node2D
class_name BaseWeapon

@onready var fire_timer = $Timer 
@onready var bullet_point = $BulletPoint
@onready var anim = $AnimatedSprite2D
@onready var fireAudio = $FireAudio

@export var bullets_per_magazine = 30  # 每弹夹子弹数
@export var max_magazine_counts = 5 # 最大弹夹数量
@export var total_bullets_counts = 150  # 武器的总子弹数量
@export var weapon_rof = 0.5  # 射速 射击间隔（秒）
@export var damage = 5
@export var weapon_name = '默认枪械'
@export var weapon_camera_offset_interval = 0.2
@export var weapon_camera_offset_magnitude:Vector2 = Vector2(-1,2) 
@export var fire_audio = preload("res://audio/wpn_fire_hk416.mp3");

# 后坐力参数
@export var thrust_distance: float = 2.0    # 推力距离（像素，父节点后移）
@export var upward_rotation: float = -50.0     # 向上旋转角度（度，父节点上抬）
@export var thrust_duration: float = 0.03    # 推力持续时间（秒）
@export var rotation_duration: float = 0.06  # 旋转持续时间（秒）
@export var recovery_ease: Tween.EaseType = Tween.EASE_OUT  # 恢复缓动曲线


var _pre_bullet = preload("res://scene/bullet/BaseBullet.tscn")
var _shell:PackedScene = load("res://scene/bullet/bulletCasing/BulletCasing.tscn")

@onready var sprite = $AnimatedSprite2D

var current_bullet_count_in_single_magazine = 0 # 在当前弹夹中所有的子弹数量
var current_magazine_counts = 0 # 当前所剩余的弹夹数量
var current_nearness_enemy_target = null # 当前贴近的敌人

var can_shoot = true

func _on_fire_timer_timeout():
	can_shoot = true

func _ready() -> void:
	fireAudio.stream = fire_audio
	fire_timer.wait_time = weapon_rof
	fire_timer.one_shot = true  # 单次触发
	fire_timer.connect("timeout", _on_fire_timer_timeout)

func getCurRotateDeg():
	pass

func getBollPointPos():
	return bullet_point.global_position

func shoot(parent: Node2D,hand:Node2D):
	if can_shoot == false:
		return
	
	can_shoot = false
	anim.play("shoot")
	fire_timer.start()
	camera_offset()
	var tween_thrust_restore=apply_thrust(parent,hand)
	var tween_rotation_restore=apply_rotation(parent)
	fireAudio.play()
	#shell_gpu.restart()
	#shell_gpu.emitting = true
	#shell_gpu.amount = max(shell_gpu.amount, 10)  # 确保 amount 足够
	#shell_gpu.emitting = true
	#shell_gpu.amount_ratio = 1.0 / shell_gpu.amount  # 只发射1个（如果amount>1）
	#shell_gpu.restart()  # 重启粒子系统，发射新粒子
	#shell_gpu.amount += 1  # 增加 amount 以支持新粒子
	#shell_gpu.finished.connect(func ():
		#shell_gpu.emitting = false
		#)

	
	var instance;
	if current_nearness_enemy_target:
		instance = _pre_bullet.instantiate()
		instance.handle_hurt(current_nearness_enemy_target)
		return
	
	instance = _pre_bullet.instantiate()
	instance.global_position = bullet_point.global_position
	
	# 使用枪械的朝向计算子弹方向
	#var direction = Vector2(cos(anim.global_rotation), sin(anim.global_rotation)).normalized()
	var mouse_pos = get_global_mouse_position()
	var direction:Vector2 = (mouse_pos - bullet_point.global_position).normalized()
	instance.dir = direction
	
	# 设置子弹旋转，使长方形朝向与移动方向一致
	#print('global_rotation is ',global_rotation)
	instance.rotation = anim.global_rotation
	
	GameManager.getMapInstance().addEntityToBulletViewer(instance)
	
	var sh=_shell.instantiate()


	var isNormal= GameManager.getPlayerInstance().body.scale.x == 1
	var deg:Vector2;
	if isNormal:
		deg=Tools.get_random_unit_vector([-140,-130])
		#var gravity=direction.rotated(PI / 2).normalized() * 200
		#rotated_vector =direction.rotated(-(PI * 3) / 4)
		#sh.process_material.gravity = Vector3(gravity.x,gravity.y,0)
		#sh.process_material.direction = Vector3(rotated_vector.x,rotated_vector.y,0)
	else:
		deg=Tools.get_random_unit_vector([-50,-40])
		#var gravity=direction.rotated(-PI / 2).normalized() * 200
		#rotated_vector =direction.rotated(PI-(PI) / 4)
		#sh.process_material.gravity = Vector3(gravity.x,gravity.y,0)
		#sh.process_material.direction = Vector3(rotated_vector.x,rotated_vector.y,0)
	#sh.setup()
	sh.dir = deg
	sh.global_position = GameManager.getPlayerInstance().get_shell_pos()
	GameManager.getMapInstance().addEntityToViewer(sh)
	
	apply_thrust_restore(parent,hand,tween_thrust_restore)
	apply_rotation_restore(parent,tween_rotation_restore)
	# 弹出壳体
	#CasingManager.eject_casing(getShellPos(), GameManager.getPlayerPos(),direction)
	
	#await anim.animation_finished


func _on_area_2d_body_entered(body: Node2D) -> void:
	current_nearness_enemy_target = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if current_nearness_enemy_target == body:
		current_nearness_enemy_target = null
		
func camera_offset():
	var tween = create_tween()
	var player=GameManager.getPlayerInstance()
	tween.tween_property(player.cameraViewer,'offset',Vector2.ZERO,weapon_camera_offset_interval).from(weapon_camera_offset_magnitude)
	pass

# 施加推力（父节点的线性后移）
func apply_thrust(parent: Node2D,hand:Node2D) -> Tween:
	var initial_position = parent.position
	var hand_initial_position = hand.position
	var thrust_direction = -global_transform.x.normalized()  # 使用武器的朝向
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 快速后移
	tween.tween_property(parent, "position", initial_position + thrust_direction * thrust_distance, thrust_duration)
	tween.tween_property(hand, "position", hand_initial_position + thrust_direction * thrust_distance, thrust_duration)
	return tween
	

func apply_thrust_restore(parent: Node2D,hand:Node2D,tween):
	var initial_position = parent.position
	var hand_initial_position = hand.position
	# 恢复
	tween.tween_property(parent, "position", initial_position, thrust_duration).set_ease(recovery_ease)
	tween.tween_property(hand, "position", hand_initial_position, thrust_duration).set_ease(recovery_ease)
	


# 施加旋转（父节点的枪口上抬）
func apply_rotation(parent: Node2D) -> Tween:
	var initial_rotation = parent.rotation_degrees
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 向上旋转
	tween.tween_property(parent, "rotation_degrees", initial_rotation + upward_rotation, rotation_duration)
	return tween
	
func apply_rotation_restore(parent: Node2D,tween:Tween):
	# 恢复
	var initial_rotation = parent.rotation_degrees
	tween.tween_property(parent, "rotation_degrees", initial_rotation, rotation_duration).set_ease(recovery_ease)
	


	
