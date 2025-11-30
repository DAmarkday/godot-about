extends CharacterBody2D

var ship_speed: float = 200
var rotation_speed: float = 10.0
var max_line_length: float = 400.0
var line_extend_speed: float = 250.0     # Q拉长速度
var line_retract_speed: float = 350.0    # E缩短速度
var pull_force_multiplier: float = 20.0  # 超长时的拉力倍数
@onready var sprite_node = $Sprite2D

# 钓鱼线状态
var fishing_line: Line2D
var is_casted: bool = false
var anchor_point: Vector2 = Vector2.ZERO # 鱼钩固定位置（全局）
var fixed_line_length: float = 0.0       # 当前线长（可变）

func _ready():
	create_ship()
	global_position = Vector2(300, 300)
	fishing_line = Line2D.new()
	fishing_line.name = "FishingLine"
	fishing_line.width = 4
	fishing_line.default_color = Color(1, 1, 1, 0.85)
	fishing_line.antialiased = true
	fishing_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	fishing_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(fishing_line)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 按下鼠标左键：抛竿/开始拉线
			if not is_casted:
				cast_line()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# 按下鼠标右键：取消拉线/收线
			reel_in()

func cast_line():
	var head_pos = sprite_node.get_node("shipHead").global_position
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - head_pos).normalized()
	var dist = head_pos.distance_to(mouse_pos)
	if dist > max_line_length:
		dist = max_line_length
	fixed_line_length = dist
	anchor_point = head_pos + dir * dist # 鱼钩位置固定在此！
	is_casted = true

func reel_in():
	is_casted = false
	fixed_line_length = 0.0

func update_line():
	if !is_casted:
		fishing_line.clear_points()
		return
	var head_global = sprite_node.get_node("shipHead").global_position
	var start = fishing_line.to_local(head_global)
	var end = fishing_line.to_local(anchor_point)
	fishing_line.clear_points()
	fishing_line.add_point(start)
	fishing_line.add_point(end)

func _process(_delta):
	update_line()

func _physics_process(delta):
	# —— 玩家手动移动 ——
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("up"): input_dir.y -= 1
	if Input.is_action_pressed("down"): input_dir.y += 1
	if Input.is_action_pressed("left"): input_dir.x -= 1
	if Input.is_action_pressed("right"): input_dir.x += 1
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		velocity = input_dir * ship_speed
	
	# —— 判断是否在拉线（按住Q或E）——
	var is_pulling = Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_E)
	
	# —— 核心：鱼线拉力 & 手动调整线长 ——
	if is_casted:
		# 手动调整线长
		if Input.is_key_pressed(KEY_Q):
			# 按住Q：拉长线
			fixed_line_length += line_extend_speed * delta
			fixed_line_length = min(fixed_line_length, max_line_length)
		if Input.is_key_pressed(KEY_E):
			# 按住E：缩短线
			fixed_line_length -= line_retract_speed * delta
			fixed_line_length = max(30.0, fixed_line_length)
		
		# 基础拉力：超过当前线长就拉回船头
		var head_pos = sprite_node.get_node("shipHead").global_position
		var to_anchor = anchor_point - head_pos
		var current_dist = to_anchor.length()
		if current_dist > fixed_line_length:
			var pull_dir = to_anchor.normalized()
			var excess = current_dist - fixed_line_length
			velocity += pull_dir * excess * pull_force_multiplier
	
	move_and_slide()
	
	# —— 船头朝向（拉线时不影响方向）——
	var head_pos = sprite_node.get_node("shipHead").global_position
	if is_casted and not is_pulling:
		# 未拉线时：朝向鱼钩
		var dir = (anchor_point - head_pos).normalized()
		sprite_node.rotation = lerp_angle(sprite_node.rotation, dir.angle(), rotation_speed * delta)
	elif input_dir.length() > 0:
		# 有输入时：朝向移动方向
		sprite_node.rotation = lerp_angle(sprite_node.rotation, input_dir.angle(), rotation_speed * delta)

# 你的 create_ship 完全不变
func create_ship():
	var body = ColorRect.new()
	body.name = "Body"
	body.color = Color("blue")
	body.size = Vector2(90, 40)
	body.position = Vector2(-45, -20)
	sprite_node.add_child(body)
	var head = ColorRect.new()
	head.name = "shipHead"
	head.color = Color("yellow")
	head.size = Vector2(30, 16)
	head.position = Vector2(30, -8)
	sprite_node.add_child(head)
