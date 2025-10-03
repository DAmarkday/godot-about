
extends CharacterBody2D
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D

@export var gravity: float = 9.8

var player_pos:Vector2 = Vector2.ZERO
var bound:float = 0     # 落地点的y坐标 初始化为使用者的y坐标
var setted_bound_range:float = randi_range(-30,30)      # 范围
var motion: Vector2 = Vector2.ZERO # 初始速度
var dir:Vector2 = get_random_unit_vector();
var init_x_speed_counts = 100
var init_y_speed_counts = 200
@onready var timer:Timer = $Timer
#var start_time: float = 0.0
#@export var lifetime: float = 1.5  # 总存活时间
var topP=0; # top point一定是最小的 初始化为初始位置
var is_arrived_top:bool = false
func ani_play():
	var w=randi_range(1,6)
	var isFlip=randi_range(0,1)
	anim.flip_h=[false,true][isFlip]
	anim.frame  = w

func _ready() -> void:
	#start_time = Time.get_unix_time_from_system()
	motion = Vector2(dir.x*init_x_speed_counts,dir.y* init_y_speed_counts)
	bound = GameManager.getPlayerPos().y
	topP = global_position.y
	velocity = motion
	
	timer.wait_time = 0.2
	timer.one_shot = false  # 持续触发
	timer.connect("timeout", ani_play)  # 连接 Timer 的 timeout 信号
	timer.start()
	
func _physics_process(delta):
	apply_bound(delta)

func get_random_unit_vector(random_range:Array=[-110, -160]) -> Vector2:
	# 生成 0 到 180 度的随机角度（转换为弧度）
	var angle_degrees = randf_range(random_range[0], random_range[1])
	var angle_radians = deg_to_rad(angle_degrees)
	
	# 使用 cos 和 sin 计算单位向量的 x 和 y 分量
	var unit_vector = Vector2(cos(angle_radians), sin(angle_radians))
	
	return unit_vector
	
func apply_bound(_delta):
	var curP = global_position.y
	#print('1111 ',curP," ",topP)
	
	if topP>=curP:
		topP = curP
		is_arrived_top = false
		print("没有到达顶部")
		if (abs(motion.y) < 1.0):
			#到达顶部时暂停
			timer.paused = true
	else:
		if not is_arrived_top:
			bound = player_pos.y + setted_bound_range
			is_arrived_top = true
			print("到达过顶部")
			if (abs(motion.y) >= 1.0 and not timer.paused):
				#超过顶部后启动
				timer.paused = true
		# 下降
		pass

	# Should Fall
	if (global_position.y < bound):
		motion = motion.move_toward(Vector2(motion.x, motion.y + gravity), gravity)
		print("下落")
	# Should bounce
	else:
		motion.y = -0.7 * motion.y
		motion.x = 0.5 * motion.x
		print("反弹")
		if motion.length()<=1:
			#到达底部时停止
			if not timer.is_stopped():
				timer.stop()
				set_physics_process(false)
	
				await get_tree().create_timer(1.5).timeout
				# 落地后动画：缩放 + 淡出
				#var time_passed = Time.get_unix_time_from_system() - start_time
				#var fade_time = max(1, lifetime - time_passed)  # 确保至少1秒淡出
				var fade_time = 2
				var tween = create_tween()
				tween.tween_property(self, "scale", Vector2(0.7, 0.7), fade_time)
				tween.parallel().tween_property(self, "modulate:a", 0.0, fade_time)
				tween.tween_callback(func(): queue_free())  # 通知 CasingManager 回收
	
		
	velocity = motion
	move_and_slide()
