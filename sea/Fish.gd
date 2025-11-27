extends Node2D

# 可调节参数
@export var swim_speed: float = 60.0
@export var turn_speed: float = 2.5
@export var tail_wiggle_speed: float = 8.0
@export var tail_wiggle_amount: float = 15.0

var direction: Vector2 = Vector2.RIGHT
var target_angle: float = 0.0
var screen_size: Vector2

# 正确的类型声明
@onready var sprite: Node2D = $Sprite
@onready var tail: Node2D = $Sprite/Tail                  # 尾巴的父节点（用来摆动）
@onready var pupil_left: ColorRect = $Sprite/EyeLeft/PupilLeft
@onready var pupil_right: ColorRect = $Sprite/EyeRight/PupilRight

func _ready():
	screen_size = get_viewport_rect().size
	
	# 如果你还没有在编辑器里手动建外观，就自动创建
	if not $Sprite:
		create_fish_visual()
	
	choose_new_direction()

func create_fish_visual():
	# 主外观容器
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
	
	# 尾巴（用一个 Node2D 包着，方便单独摆动）
	var tail_container = Node2D.new()
	tail_container.name = "Tail"
	tail_container.position = Vector2(-45, 0)  # 尾巴根部对齐身体左端
	sprite.add_child(tail_container)
	tail = tail_container                                 # 关键：tail 是 Node2D
	
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

func choose_new_direction():
	target_angle = randf_range(-PI, PI)

func _process(delta):
	# 1. 平滑转向
	var angle_diff = angle_difference(global_rotation, target_angle)
	global_rotation += sign(angle_diff) * min(abs(angle_diff), turn_speed * delta)
	
	# 2. 尾巴摆动
	tail.rotation = sin(Time.get_ticks_msec() * 0.001 * tail_wiggle_speed) * deg_to_rad(tail_wiggle_amount)
	
	# 3. 瞳孔始终朝前
	var forward = Vector2(cos(global_rotation), sin(global_rotation))
	pupil_left.position = Vector2(3, 3) + forward * 2.0
	pupil_right.position = Vector2(3, 3) + forward * 2.0
	
	# 4. 前进
	global_position += forward * swim_speed * delta
	
	# 5. 边界检测（靠近边缘就掉头）
	var margin = 100.0
	var should_turn = false
	var to_center = Vector2.ZERO
	
	if global_position.x < margin or global_position.x > screen_size.x - margin:
		should_turn = true
	if global_position.y < margin or global_position.y > screen_size.y - margin:
		should_turn = true
	
	if should_turn:
		to_center = (screen_size * 0.5 - global_position).normalized()
		target_angle = atan2(to_center.y, to_center.x)
	else:
		# 平时随机换方向（大约每 2~5 秒换一次）
		if randf() < delta * 0.4:
			choose_new_direction()
