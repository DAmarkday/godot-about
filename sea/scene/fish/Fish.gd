extends CharacterBody2D

@export var swim_speed: float = 5000          # 像素/秒（固定前进速度）
@export var rotation_speed: float = 0.7        # 新的：每秒最大转向弧度（大鱼建议 0.5~1.2）
@export var turn_acceleration: float = 0.5    # 新的：转向加速度（越小越笨重，推荐 0.4~0.8）
@export var tail_wiggle_speed: float = 6.0
@export var tail_wiggle_amount: float = 40


var current_angular_velocity: float = 0.0      # 当前角速度（关键！模拟惯性）
var target_angle: float = 0.0
var physics_tick_rate: float = Engine.get_physics_ticks_per_second()

@onready var sprite: Node2D = $Sprite
@onready var tail: Node2D = $Sprite/Tail
@onready var pupil_left: ColorRect = $Sprite/EyeLeft/PupilLeft
@onready var pupil_right: ColorRect = $Sprite/EyeRight/PupilRight

func _ready() -> void:
	add_to_group("fish")
	if not sprite:
		create_fish_visual()
	choose_new_direction()

# ==================== 核心物理（完全不依赖 delta）===================
func _physics_process(_delta: float) -> void:
	if $"../Rope".pause == true:
		swim_speed = 5000
	else:
		swim_speed = 10000
	per_pp()

# 每秒固定概率随机转向 + 边界反弹
var _time_since_last_random: float = 0.0
func _check_bounds_and_random_turn() -> void:
	const MARGIN := 120.0
	const RANDOM_TURN_CHANCE_PER_SECOND := 0.25  # 大鱼更“固执”，降低随机转向概率

	var screen := get_viewport_rect().size
	var pos := global_position

	# 靠近边界时强制转向回中心（像大船避礁石）
	if pos.x < MARGIN or pos.x > screen.x - MARGIN or \
	   pos.y < MARGIN or pos.y > screen.y - MARGIN:
		var to_center := (screen * 0.5 - pos).normalized()
		target_angle = to_center.angle()
		return

	# 随机转向（每秒判断一次）
	_time_since_last_random += 1.0 / physics_tick_rate
	if _time_since_last_random >= 1.0:
		_time_since_last_random -= 1.0
		if randf() < RANDOM_TURN_CHANCE_PER_SECOND:
			choose_new_direction()

# 真正的大鱼转向逻辑（带加速度 + 角速度惯性）
func per_pp() -> void:
	# 1. 计算目标角度与当前朝向的差值（最短路径）
	var angle_diff := wrapf(target_angle - global_rotation, -PI, PI)

	# 2. 目标角速度 = 角度差 × 比例系数（越大转向越激进）
	var desired_angular_velocity := angle_diff * turn_acceleration

	# 3. 限制最大角速度（这就是“大船感”的核心！）
	desired_angular_velocity = clampf(
		desired_angular_velocity,
		-rotation_speed / physics_tick_rate,
		rotation_speed / physics_tick_rate
	)

	# 4. 平滑逼近目标角速度（模拟转向舵的响应速度）
	current_angular_velocity = lerp(
		current_angular_velocity,
		desired_angular_velocity,
		0.1   # 这个值越小，转向越“迟钝”，建议 0.05~0.15
	)

	# 5. 应用角速度
	global_rotation += current_angular_velocity

	# 6. 固定速度前进（大鱼永远匀速游）
	var forward := Vector2(cos(global_rotation), sin(global_rotation))
	velocity = forward * (swim_speed / physics_tick_rate)

	# 7. 尾巴摆动（稍微慢一点更有力量感）
	var time_sec := Time.get_ticks_msec() * 0.001
	tail.rotation = sin(time_sec * tail_wiggle_speed * TAU) * deg_to_rad(tail_wiggle_amount)

	# 8. 眼睛始终朝前
	pupil_left.position  = Vector2(3, 3) + forward * 2.5
	pupil_right.position = Vector2(3, 3) + forward * 2.5

	# 9. 边界与随机转向检查
	_check_bounds_and_random_turn()

	# 10. 移动 + 碰撞
	move_and_slide()

func choose_new_direction() -> void:
	# 大鱼不会突然180度急转，限制转向角度范围
	var current := global_rotation
	var random_offset := randf_range(-PI * 0.6, PI * 0.6)  # 最大偏转 ±108°
	target_angle = current + random_offset
	# 或者完全随机也可以，但上面这种更“稳重”
	# target_angle = randf_range(-PI, PI)

# ==================== 视觉创建代码保持不变 ====================
# （直接复制你原来的 create_fish_visual()，这里省略以节省篇幅）
# 你原来的函数完全可以直接粘贴到这里，一点都不用改

# -------------------------------------------------
# 下面保持你原来的视觉创建代码（不变）
# -------------------------------------------------
func create_fish_visual() -> void:
	var sprite_node = Node2D.new()
	sprite_node.name = "Sprite"
	add_child(sprite_node)
	sprite = sprite_node

	# 身体
	var body = ColorRect.new()
	body.name = "Body"
	body.color = Color("#ff9500")
	body.size = Vector2(90, 40)
	body.position = Vector2(-45, -20)
	sprite.add_child(body)

	# 尾巴容器
	var tail_container = Node2D.new()
	tail_container.name = "Tail"
	tail_container.position = Vector2(-45, 0)
	sprite.add_child(tail_container)
	tail = tail_container

	var tail_rect = ColorRect.new()
	tail_rect.color = Color("#e64500")
	tail_rect.size = Vector2(30, 26)
	tail_rect.position = Vector2(-30, -13)
	tail_container.add_child(tail_rect)

	# 左眼
	var eye_l = ColorRect.new()
	eye_l.name = "EyeLeft"
	eye_l.color = Color.WHITE
	eye_l.size = Vector2(12, 12)
	eye_l.position = Vector2(15, -12)
	sprite.add_child(eye_l)

	var pupil_l = ColorRect.new()
	pupil_l.name = "PupilLeft"
	pupil_l.color = Color.BLACK
	pupil_l.size = Vector2(6, 6)
	pupil_l.position = Vector2(3, 3)
	eye_l.add_child(pupil_l)
	pupil_left = pupil_l

	# 右眼
	var eye_r = ColorRect.new()
	eye_r.name = "EyeRight"
	eye_r.color = Color.WHITE
	eye_r.size = Vector2(12, 12)
	eye_r.position = Vector2(35, -12)
	sprite.add_child(eye_r)

	var pupil_r = ColorRect.new()
	pupil_r.name = "PupilRight"
	pupil_r.color = Color.BLACK
	pupil_r.size = Vector2(6, 6)
	pupil_r.position = Vector2(3, 3)
	eye_r.add_child(pupil_r)
	pupil_right = pupil_r
