
extends CharacterBody2D
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D

@export var gravity: float = 7 

var player_pos:Vector2 = Vector2.ZERO
var bound:float = randi_range(0,30)      # 范围
var motion: Vector2 = Vector2.ZERO # 初始速度
var dir:Vector2 = get_random_unit_vector();
var init_x_speed_counts = 100
var init_y_speed_counts = 200
@onready var timer = $Timer
func ani_play():
	var w=randi_range(1,6)
	var isFlip=randi_range(0,1)
	anim.flip_h=[false,true][isFlip]
	anim.frame  = w

func _ready() -> void:
	motion = Vector2(dir.x*init_x_speed_counts,dir.y* init_y_speed_counts)
	velocity = motion
	timer.wait_time = 0.2
	timer.one_shot = false  # 持续触发
	timer.connect("timeout", ani_play)  # 连接 Timer 的 timeout 信号
	timer.start()
	
func _physics_process(delta):
	apply_bound(delta)

func get_random_unit_vector(range:Array=[-110, -160]) -> Vector2:
	# 生成 0 到 180 度的随机角度（转换为弧度）
	var angle_degrees = randf_range(range[0], range[1])
	var angle_radians = deg_to_rad(angle_degrees)
	
	# 使用 cos 和 sin 计算单位向量的 x 和 y 分量
	var unit_vector = Vector2(cos(angle_radians), sin(angle_radians))
	
	return unit_vector

func apply_bound(_delta):
	# Should Fall
	if (global_position.y < player_pos.y + bound):
		motion = motion.move_toward(Vector2(motion.x, motion.y + gravity), gravity)
	# Should bounce
	else:
		motion.y = -0.50 * motion.y
		motion.x = 0.5 * motion.x
	## Stop physics to prevent performance issues
	if (abs(motion.y) < 1.0):
		#到达顶部或底部时都暂停
		timer.paused = true
	else:
		timer.paused = false
		pass
		
	if velocity == Vector2.ZERO:
		set_physics_process(false)
		
	velocity = motion
	move_and_slide()
