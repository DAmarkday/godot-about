extends CharacterBody2D

var ship_speed: float = 200
var rotation_speed: float = 10.0
var max_line_length: float = 400.0
var reel_force_when_holding_e: float = 1800.0   # 按住E时被拉的力度（越大越猛）

@onready var sprite_node = $Sprite2D

# 钓鱼线状态
var fishing_line: Line2D
var is_casted: bool = false
var anchor_point: Vector2 = Vector2.ZERO     # 鱼钩固定位置（全局，永远不动！）
var fixed_line_length: float = 0.0           # 抛竿时确定的长度（之后可被收短）

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
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		if is_casted:
			reel_in()        # 第二次按Q → 断线
		else:
			cast_line()      # 第一次按Q → 抛竿

func cast_line():
	var head_pos = sprite_node.get_node("shipHead").global_position
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - head_pos).normalized()
	var dist = head_pos.distance_to(mouse_pos)
	
	if dist > max_line_length:
		dist = max_line_length
	
	fixed_line_length = dist
	anchor_point = head_pos + dir * dist   # 鱼钩位置固定在此！
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
	var end   = fishing_line.to_local(anchor_point)
	fishing_line.clear_points()
	fishing_line.add_point(start)
	fishing_line.add_point(end)

func _process(_delta):
	update_line()

func _physics_process(delta):
	# —— 玩家手动移动 ——
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("up"):    input_dir.y -= 1
	if Input.is_action_pressed("down"):  input_dir.y += 1
	if Input.is_action_pressed("left"):  input_dir.x -= 1
	if Input.is_action_pressed("right"): input_dir.x += 1
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * ship_speed

	# —— 核心：鱼线拉力 ——
	if is_casted:
		var head_pos = sprite_node.get_node("shipHead").global_position
		var to_anchor = anchor_point - head_pos
		var current_dist = to_anchor.length()
		
		# 基础拉力：超过固定长度就强力拉回
		if current_dist > fixed_line_length:
			var pull_dir = to_anchor.normalized()
			var excess = current_dist - fixed_line_length
			velocity += pull_dir * excess * 15.0   # 超长拉力

		# 按住E时：额外超级大拉力，把船猛地拽向鱼钩！
		if Input.is_key_pressed(KEY_E):
			var reel_dir = to_anchor.normalized()
			velocity += reel_dir * reel_force_when_holding_e * delta
			# 可视化反馈：收线时长度也慢慢变短（真实感）
			fixed_line_length = max(15.0, fixed_line_length - 300 * delta)

	move_and_slide()

	# —— 船头朝向 ——
	if is_casted:
		var head_pos = sprite_node.get_node("shipHead").global_position
		var dir = (anchor_point - head_pos).normalized()
		sprite_node.rotation = lerp_angle(sprite_node.rotation, dir.angle(), rotation_speed * delta)
	elif input_dir.length() > 0:
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
