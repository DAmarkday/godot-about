extends CharacterBody2D

class_name BaseEnemy

# 状态与动画映射
const STATE_ANIM_MAP: Dictionary = {
	State.CREAT: "create",
	State.IDLE: "idle",
	State.PATROL: "move",
	State.MOVE: "move",
	State.ATK: "attack",
	State.HIT: "hit",
	State.DEATH: "death"
}

# 导出属性，便于编辑器调整
@export var speed: float = 25.0
@export var detection_range: float = 200.0
@export var idle_interval: float = 1.0
@export var attack_cooldown: float = 1.0
@export var max_health: int = 100
@export var patrol_radius_min: float = 100.0
@export var patrol_radius_max: float = 300.0
@export var patrol_duration: float = 5.0
@export var navigation_threshold: float = 4.0
@export var path_desired_distance: float = 10.0  # 新增：导航路径点距离阈值，防止跳跃
@export var velocity_flip_threshold: float = 1.0  # 增大阈值，减少低速抖动

# 节点引用
@onready var anim: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var body: Node2D = $Body
@onready var shadow: Node2D = $Shadow
@onready var coll: CollisionShape2D = $CollisionShape2D
@onready var nav: NavigationAgent2D = $NavigationRegion  # 修正：假设为 NavigationAgent2D 节点

# 状态机
enum State { CREAT, IDLE, PATROL, MOVE, ATK, HIT, DEATH }
var current_state: State = State.CREAT

# 计时器
var timer: Timer
var attack_timer: Timer
var patrol_timer: Timer

# 状态变量
var is_alive: bool = true
#var current_health: int
var patrol_target: Vector2 = Vector2.ZERO
var is_performing_attack: bool = false
var facing_direction: float = 1.0  # 面向方向 (1.0: 右, -1.0: 左)
var last_velocity_dir: float = 1.0  # 新增：最后移动方向，用于静止状态翻转

# 信号，用于与其他系统集成
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
	#current_health = max_health

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
	add_child(attack_timer)

	patrol_timer = Timer.new()
	patrol_timer.wait_time = patrol_duration
	patrol_timer.one_shot = true
	patrol_timer.timeout.connect(_on_patrol_timeout)
	add_child(patrol_timer)

	# 启动创建状态
	if current_state == State.CREAT:
		change_anim()
		anim.animation_finished.connect(_on_create_finished, CONNECT_ONE_SHOT)

func _on_create_finished() -> void:
	current_state = State.IDLE
	change_anim()

func _physics_process(delta: float) -> void:
	if not is_alive or current_state == State.CREAT:
		return

	# 获取玩家位置
	var player_pos = GameManager.getPlayerPos()
	if player_pos == Vector2.ZERO:
		return

	# 检查玩家是否在检测范围内，优先切换到 MOVE
	var dist_sq = global_position.distance_squared_to(player_pos)
	if dist_sq < detection_range * detection_range and current_state not in [State.ATK, State.HIT, State.DEATH]:
		current_state = State.MOVE

	# 更新面向方向（仅在静止状态）
	if velocity.length() < velocity_flip_threshold:
		update_facing_direction(player_pos)

	# 翻转 sprite 朝向：优先使用 velocity，若接近零则使用 last_velocity_dir
	var flip_scale: float
	if velocity.length() > velocity_flip_threshold:
		flip_scale = sign(velocity.x) if velocity.x != 0 else last_velocity_dir
		last_velocity_dir = flip_scale  # 更新最后方向
	else:
		flip_scale = last_velocity_dir  # 使用最后移动方向，避免倒转
	body.scale.x = flip_scale

	# 状态机分派
	match current_state:
		State.IDLE:
			_handle_idle()
		State.PATROL:
			_handle_patrol()
		State.MOVE:
			_handle_move()
		State.ATK:
			_handle_attack()
		State.HIT:
			_handle_hit()
		State.DEATH:
			_handle_death()

	move_and_slide()
	change_anim()

# 更新面向方向，仅在静止时基于目标位置
func update_facing_direction(target_pos: Vector2) -> void:
	var target: Vector2 = target_pos  # 默认面向玩家
	if current_state == State.PATROL and patrol_target != Vector2.ZERO:
		target = patrol_target
	
	if target != Vector2.ZERO:
		var dir_to_target = (target - global_position).normalized()
		var new_dir = sign(dir_to_target.x) if dir_to_target.x != 0 else facing_direction
		if new_dir != 0:
			facing_direction = new_dir
			last_velocity_dir = new_dir  # 同步最后方向

func _handle_idle() -> void:
	velocity = Vector2.ZERO
	if timer.is_stopped():
		timer.start()

func _handle_patrol() -> void:
	if patrol_target == Vector2.ZERO:
		var angle = randf() * TAU
		var radius = randf_range(patrol_radius_min, patrol_radius_max)
		patrol_target = global_position + Vector2.from_angle(angle) * radius
		nav.target_position = patrol_target

	var next_pos = nav.get_next_path_position()
	var to_next_dist = global_position.distance_to(next_pos)
	if to_next_dist > navigation_threshold:
		velocity = (next_pos - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO
		patrol_target = Vector2.ZERO  # 重置目标

func _handle_move() -> void:
	var player_pos = GameManager.getPlayerPos()
	var dist_sq = global_position.distance_squared_to(player_pos)
	if dist_sq > detection_range * detection_range:
		# 关键修复：切换到 IDLE 时重置导航和方向
		current_state = State.IDLE
		nav.target_position = global_position  # 重置路径，清除缓存
		velocity = Vector2.ZERO  # 强制停止
		# 更新最后方向基于当前玩家位置，避免倒转
		var dir_to_player = (player_pos - global_position).normalized()
		last_velocity_dir = sign(dir_to_player.x) if dir_to_player.x != 0 else last_velocity_dir
		print("Switched to IDLE: Reset nav and dir to ", last_velocity_dir)  # 调试输出
		return

	nav.target_position = player_pos
	var next_pos = nav.get_next_path_position()
	var to_next_dist = global_position.distance_to(next_pos)
	if to_next_dist > navigation_threshold:
		velocity = (next_pos - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO

func _handle_attack() -> void:
	velocity = Vector2.ZERO
	if attack_timer.is_stopped() and not is_performing_attack:
		perform_attack()

func perform_attack() -> void:
	if is_performing_attack:
		return
	is_performing_attack = true
	# 更新方向面向玩家
	var player_pos = GameManager.getPlayerPos()
	update_facing_direction(player_pos)
	change_anim()
	anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	is_performing_attack = false
	attack_timer.start()

func _handle_hit() -> void:
	velocity = Vector2.ZERO

func _handle_death() -> void:
	velocity = Vector2.ZERO

func _on_patrol_timeout() -> void:
	current_state = State.IDLE
	patrol_target = Vector2.ZERO
	nav.target_position = global_position  # 重置导航

func _on_idle_timer_timeout() -> void:
	if current_state == State.IDLE:
		current_state = State.PATROL
		patrol_timer.start()

func take_damage(damage: int = 10) -> void:
	if not is_alive:
		return
	#current_health -= damage
	#damaged.emit(damage)
	#if current_health <= 0:
		#die()
	#else:
		#hit()

func hit() -> void:
	if not is_alive:
		return
	current_state = State.HIT
	velocity = Vector2.ZERO  # 强制停止
	change_anim()
	anim.animation_finished.connect(_on_hit_finished, CONNECT_ONE_SHOT)

func _on_hit_finished() -> void:
	if is_alive:
		current_state = State.IDLE
		change_anim()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	current_state = State.DEATH
	velocity = Vector2.ZERO
	change_anim()
	anim.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)

func _on_death_finished() -> void:
	died.emit()
	queue_free()

func change_anim() -> void:
	if not is_alive:
		return
	var target_anim: String = STATE_ANIM_MAP[current_state]
	if current_state in [State.IDLE, State.PATROL, State.MOVE]:
		target_anim = "move" if velocity.length() > velocity_flip_threshold else "idle"
	if anim.animation != target_anim:
		anim.play(target_anim)

func _on_atk_area_body_entered(body: Node2D) -> void:
	if body is Player and current_state != State.DEATH:
		current_state = State.ATK

func _on_atk_area_body_exited(body: Node2D) -> void:
	if body is Player and current_state != State.DEATH:
		current_state = State.IDLE

# 可选：检查是否面向目标
func is_facing_target() -> bool:
	var player_pos = GameManager.getPlayerPos()
	var dir_to_target = (player_pos - global_position).normalized()
	var facing_dir = Vector2(last_velocity_dir, 0).normalized()
	return facing_dir.dot(dir_to_target) >= 0.7
