extends CharacterBody2D

@export var ship_speed: float = 300.0
#var current_rope: Node2D = null

#@onready var rope_anchor: Marker2D = $RopeAnchor
@onready var sprite_node: Sprite2D = $Sprite2D

func _ready():
	#global_position = Vector2(400, 300)
	#NativeRopeServer.on_pre_pre_update.connect(per_pp)
	
	# 自动创建船头锚点
	#if not has_node("RopeAnchor"):
		#var m = Marker2D.new()
		#m.name = "RopeAnchor"
		#m.position = Vector2(55, 0)  # 船头位置
		#add_child(m)
		#rope_anchor = m
	#
	#if not has_node("Sprite2D"):
		#var s = Sprite2D.new()
		#s.name = "Sprite2D"
		#add_child(s)
		#sprite_node = s
	
	create_ship()

func create_ship():
	# 蓝色船身
	var body = ColorRect.new()
	body.color = Color("4682b4")
	body.size = Vector2(100, 50)
	body.position = Vector2(-50, -25)
	sprite_node.add_child(body)
	
	# 黄色船头
	var head = ColorRect.new()
	head.color = Color("ffd700")
	head.size = Vector2(40, 30)
	head.position = Vector2(40, -15)
	sprite_node.add_child(head)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#if current_rope: return
		shoot_rope()

func shoot_rope():
	#var fishes = get_tree().get_nodes_in_group("fish")
	#if fishes.is_empty(): return
	$"../Rope".pause = !$"../Rope".pause
	$"../Rope".visible = !$"../Rope".visible
	# 找最近的鱼（800像素内）
	#var closest: Node2D = null
	#var best_dist := 9999.0
	#for f in fishes:
		#var d = f.global_position.distance_to(rope_anchor.global_position)
		#if d < best_dist and d < 800:
			#best_dist = d
			#closest = f
	#
	#if closest:
		#var rope_instance = preload("res://scene/Rope.tscn").instantiate()
		#get_parent().add_child(rope_instance)
		#rope_instance.connect_to(rope_anchor, closest)
		#current_rope = rope_instance

func _physics_process(delta):
	per_pp(delta)
	
func per_pp(delta):
	#velocity = Vector2.ZERO
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("up"): input_dir.y -= 1
	if Input.is_action_pressed("down"): input_dir.y += 1
	if Input.is_action_pressed("left"): input_dir.x -= 1
	if Input.is_action_pressed("right"): input_dir.x += 1
	
	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * ship_speed
	# 如果没有输入，保留被鱼拖的惯性
	
	#if velocity.length() > 10:
		#rotation = lerp_angle(rotation, velocity.angle(), delta * 10)
	
	move_and_slide()
