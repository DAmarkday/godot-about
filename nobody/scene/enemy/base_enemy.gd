extends CharacterBody2D

class_name BaseEnemy

# 状态与动画映射
const STATE_ANIM_MAP: Dictionary = {
	State.CREAT: "create",
	State.IDLE: "idle",
	# 巡逻
	State.PATROL: "move",
	State.MOVE: "move",
	# 敌人消失后寻找
	State.SEARCH: "move",
	State.ATK: "attack",
	State.HIT: "hit",
	State.DEATH: "death"
}

# 导出属性，便于编辑器调整
@export var speed: float = 25.0
@export var detection_range: float = 100.0
@export var idle_interval: float = 1.0
@export var attack_cooldown: float = 1
@export var damage: int = 1
@export var max_health: int = 1000
@export var patrol_radius_min: float = 50.0
@export var patrol_radius_max: float = 100.0
@export var patrol_duration: float = 10.0
@export var navigation_threshold: float = 20.0
@export var path_desired_distance: float = 30.0  # 新增：导航路径点距离阈值，防止跳跃

# 节点引用
@onready var anim: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var anim_body: Node2D = $Body
@onready var shadow: Node2D = $Shadow
@onready var coll: CollisionShape2D = $CollisionShape2D
@onready var nav: NavigationAgent2D = $NavigationRegion
@onready var DetectionRangeVisualizer = $DetectionRangeVisualizer
@onready var detection_range_area_collision_shape: CollisionShape2D = $DetectionRangeArea/CollisionShape2D
@onready var hitAudio = $hitAudio

@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

# 状态机
enum State { CREAT, IDLE, PATROL, MOVE, ATK, HIT, DEATH, SEARCH }
var current_state: State = State.CREAT
var current_attack_target: Player = null
var current_walk_target: Player = null

# 计时器
var timer: Timer
var attack_timer: Timer

# 状态变量
var is_alive: bool = true
var current_health: int
var patrol_target_pos: Vector2 = Vector2.ZERO
var is_performing_attack: bool = false
var last_velocity_dir: float = 1.0  # 新增：最后移动方向，用于静止状态翻转
var attack_hit_frame: int = 2  # 攻击动画的“击中”帧（根据你的动画调整）
var search_pos: Vector2 = Vector2.ZERO
var search_sign: Sprite2D = null

# 信号
signal damaged(amount: int)
signal died()

func _ready() -> void:
	# 延迟初始化，确保玩家位置可用
	await get_tree().create_timer(0.1).timeout

	var player_pos = GameManager.getPlayerPos()
	if player_pos == Vector2.ZERO:
		push_error("GameManager.getPlayerPos() returned (0, 0)! Ensure player is initialized.")
		queue_free()
		return

	# 初始化生命值
	current_health = max_health

	detection_range_area_collision_shape.shape.radius = detection_range

	# 初始化导航阈值
	nav.path_desired_distance = path_desired_distance
	nav.target_desired_distance = navigation_threshold

	# 初始化计时器
	timer = Timer.new()
	timer.wait_time = idle_interval
	timer.one_shot = true
	timer.timeout.connect(_on_idle_timer_timeout)
	add_child(timer)

	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)  # 新增：连接超时信号
	add_child(attack_timer)

	# 初始化 Hitbox 和 Hurtbox
	hitbox.monitoring = false
	hurtbox.monitoring = true

	# 初始化创建状态
	if current_state == State.CREAT:
		anim.play(STATE_ANIM_MAP[State.CREAT])
		if not anim.is_connected("animation_finished", _on_create_finished):
			anim.animation_finished.connect(_on_create_finished, CONNECT_ONE_SHOT)

func _physics_process(_delta: float) -> void:
	DetectionRangeVisualizer.update_detection_range(global_position)
	
	if not is_alive or current_state == State.CREAT:
		return
	
	# 检查玩家并更新状态
	var player_pos = GameManager.getPlayerPos()
	if player_pos == Vector2.ZERO:
		set_state(State.IDLE)
		return

	# 检测目标切换
	if current_attack_target and current_state not in [State.ATK, State.HIT, State.DEATH]:
		set_state(State.ATK)
	elif current_walk_target and current_state not in [State.MOVE, State.SEARCH, State.HIT, State.DEATH]:
		set_state(State.MOVE)

	# 更新面向方向
	update_facing_direction()



	# 更新移动相关动画
	if current_state in [State.IDLE, State.PATROL, State.MOVE, State.SEARCH]:
		var target_anim = "move" if velocity != Vector2.ZERO else "idle"
		if anim.animation != target_anim:
			anim.play(target_anim)

	# 状态机分派
	match current_state:
		State.IDLE:
			_handle_idle()
		State.PATROL:
			_handle_patrol()
		State.MOVE:
			_handle_move(player_pos,true)
		State.SEARCH:
			_handle_move(search_pos)
		State.ATK:
			_handle_attack()
		State.HIT:
			_handle_hit()
		State.DEATH:
			_handle_death()

	move_and_slide()

func set_state(new_state: State) -> void:
	if current_state == new_state or not is_alive:
		return

	# 退出旧状态
	match current_state:
		State.ATK:
			is_performing_attack = false
			hitbox.monitoring = false
			if anim.is_connected("animation_finished", _on_attack_finished):
				anim.animation_finished.disconnect(_on_attack_finished)
			if anim.is_connected("frame_changed", _on_attack_frame_changed):
				anim.frame_changed.disconnect(_on_attack_frame_changed)
		State.HIT:
			if anim.is_connected("animation_finished", _on_hit_finished):
				anim.animation_finished.disconnect(_on_hit_finished)
		State.DEATH:
			if anim.is_connected("animation_finished", _on_death_finished):
				anim.animation_finished.disconnect(_on_death_finished)

	current_state = new_state

	# 进入新状态
	match current_state:
		State.CREAT:
			anim.play(STATE_ANIM_MAP[State.CREAT])
			if not anim.is_connected("animation_finished", _on_create_finished):
				anim.animation_finished.connect(_on_create_finished, CONNECT_ONE_SHOT)
		State.IDLE, State.PATROL, State.MOVE, State.SEARCH:
			# 动画由 _physics_process 根据速度更新
			pass
		State.ATK:
			is_performing_attack = true
			anim.play(STATE_ANIM_MAP[State.ATK])
			if not anim.is_connected("animation_finished", _on_attack_finished):
				anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
			if not anim.is_connected("frame_changed", _on_attack_frame_changed):
				anim.frame_changed.connect(_on_attack_frame_changed)
		State.HIT:
			anim.play(STATE_ANIM_MAP[State.HIT])
			if not anim.is_connected("animation_finished", _on_hit_finished):
				anim.animation_finished.connect(_on_hit_finished, CONNECT_ONE_SHOT)
		State.DEATH:
			anim.play(STATE_ANIM_MAP[State.DEATH])
			if not anim.is_connected("animation_finished", _on_death_finished):
				anim.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)

func update_facing_direction() -> void:
	# 翻转 sprite 朝向：优先使用 velocity，若接近零则使用 last_velocity_dir
	var flip_scale: float
	if velocity != Vector2.ZERO:
		flip_scale = sign(velocity.x) if velocity.x != 0 else last_velocity_dir
		last_velocity_dir = flip_scale  # 更新最后方向
	else:
		flip_scale = last_velocity_dir  # 使用最后移动方向，避免倒转
	anim_body.scale.x = flip_scale

func _handle_idle() -> void:
	velocity = Vector2.ZERO
	if timer.is_stopped():
		timer.start()

func _handle_patrol() -> void:
	if patrol_target_pos == Vector2.ZERO:
		var angle = randf() * TAU
		var radius = randf_range(patrol_radius_min, patrol_radius_max)
		patrol_target_pos = global_position + Vector2.from_angle(angle) * radius
		nav.target_position = patrol_target_pos

	var next_pos = nav.get_next_path_position()
	var to_next_dist = global_position.distance_to(next_pos)
	if to_next_dist > navigation_threshold:
		velocity = (next_pos - global_position).normalized() * speed
	else:
		_on_patrol_timeout()

func _handle_move(pos: Vector2,isMustArrived:bool = false) -> void:
	if pos == Vector2.ZERO:
		push_error("_handle_move pos is ZERO")
		return
	var temp_distance
	if isMustArrived:
		#if nav.path_desired_distance != 20:
			#nav.path_desired_distance = 20
		if nav.target_desired_distance != 0:
			nav.target_desired_distance = 0
		temp_distance = 0
	else:
		if nav.path_desired_distance != path_desired_distance:
			nav.path_desired_distance = path_desired_distance
		if nav.target_desired_distance != navigation_threshold:
			nav.target_desired_distance = navigation_threshold
		temp_distance = navigation_threshold
		
	nav.target_position = pos
	var next_pos = nav.get_next_path_position()
	var to_next_dist = global_position.distance_to(next_pos)
	if to_next_dist > temp_distance:
		velocity = (next_pos - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO
		set_state(State.IDLE)
		if search_sign:
			search_sign.queue_free()

func _handle_attack() -> void:
	velocity = Vector2.ZERO
	#if not current_attack_target:
		#set_state(State.IDLE)
		#return
	#if attack_timer.is_stopped() and not is_performing_attack:
		#set_state(State.ATK)

func _on_attack_timer_timeout() -> void:
	if current_attack_target and current_state == State.ATK:
		is_performing_attack = true
		anim.play(STATE_ANIM_MAP[State.ATK])
		if not anim.is_connected("animation_finished", _on_attack_finished):
			anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
		if not anim.is_connected("frame_changed", _on_attack_frame_changed):
			anim.frame_changed.connect(_on_attack_frame_changed)
			
func _on_attack_frame_changed() -> void:
	if current_state == State.ATK and anim.frame == attack_hit_frame:
		if current_attack_target:
			hitbox.monitoring = true
			current_attack_target.on_player_is_hurted.emit(5)
	else:
		hitbox.monitoring = false

func _on_attack_finished() -> void:
	is_performing_attack = false
	hitbox.monitoring = false
	if current_attack_target and current_state == State.ATK:
		attack_timer.start()
	else:
		set_state(State.IDLE if not current_walk_target else State.MOVE)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and current_state == State.ATK:
		body.take_damage(damage)
		print("Hitbox hit player, dealing damage: ", damage)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body is Area2D and body.get_parent() is Player:
		take_damage(body.get_parent().damage)  # 假设玩家有 damage 属性

func _handle_hit() -> void:
	velocity = Vector2.ZERO

func _handle_death() -> void:
	is_alive = false
	coll.disabled = true
	velocity = Vector2.ZERO

func _on_patrol_timeout() -> void:
	set_state(State.IDLE)
	patrol_target_pos = Vector2.ZERO
	nav.target_position = global_position  # 重置导航

func _on_idle_timer_timeout() -> void:
	if current_state == State.IDLE:
		set_state(State.PATROL)

func take_damage(hurt_damage: int = 2) -> void:
	if not is_alive:
		return
	current_health -= hurt_damage
	hitAudio.play()
	damaged.emit(hurt_damage)
	if current_health <= 0:
		die()
	else:
		hit()

func set_flash(value: float) -> void:
	anim.material.set_shader_parameter("flash_intensity", value)

func hit() -> void:
	if not is_alive:
		return
	if current_state != State.ATK:
		set_state(State.HIT)
	anim.material.set_shader_parameter("flash_intensity", 1.0)
	anim.material.set_shader_parameter("brightness", 2.5)
	var tween = create_tween()
	tween.tween_method(set_flash, 1.0, 0.0, 0.15)  # 0.15 秒渐隐

func _on_hit_finished() -> void:
	if is_alive:
		set_state(State.IDLE)

func die() -> void:
	if not is_alive:
		return
	set_state(State.DEATH)

func _on_death_finished() -> void:
	died.emit()
	queue_free()

func _on_create_finished() -> void:
	set_state(State.IDLE)

func _on_atk_area_body_entered(body: Node2D) -> void:
	if body is Player and current_state != State.DEATH:
		current_attack_target = body
		current_walk_target = null
		set_state(State.ATK)

func _on_atk_area_body_exited(body: Node2D) -> void:
	if body is Player and current_state != State.DEATH:
		#如果玩家在攻击范围则攻击,在攻击时如果玩家脱离了攻击范围则等待攻击完成后再切换状态
		current_attack_target = null
		if current_state == State.ATK:
			anim.animation_finished.connect(func ():
				current_walk_target = body
				, CONNECT_ONE_SHOT)
		else:
			current_walk_target = body


func _on_detection_range_area_body_entered(body: Node2D) -> void:
	if search_sign:
		search_sign.queue_free()
	if body is Player and current_state not in [State.ATK, State.DEATH]:
		current_walk_target = body
		set_state(State.MOVE)

func _on_detection_range_area_body_exited(body: Node2D) -> void:
	if body == current_walk_target:
		current_walk_target = null
		search_pos = body.global_position
		search_sign = create_circle(body.global_position, 3, 'green')
		set_state(State.SEARCH)

func create_circle(gposition: Vector2, radius: float, color: Color) -> Sprite2D:
	var sprite = Sprite2D.new()
	var texture = create_circle_texture(radius, color)
	sprite.texture = texture
	sprite.global_position = gposition
	EnemyManager.getMapInstance().addEntityToViewer(sprite)
	return sprite

func create_circle_texture(radius: float, color: Color) -> ImageTexture:
	var image = Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			if Vector2(x, y).length() <= radius:
				image.set_pixel(round(x + radius), round(y + radius), color)
	var texture = ImageTexture.create_from_image(image)
	return texture
