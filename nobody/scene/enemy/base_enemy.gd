extends CharacterBody2D

class_name BaseEnemy

# 导出属性
@export var speed: float = 25.0  # 提高速度，适应大多数场景
@export var detection_range: float = 500.0  # 增大检测范围
@export var attack_range: float = 30.0
@export var idle_interval: float = 1.0  # 缩短间歇时间
@export var attack_cooldown: float = 1.0

# 节点引用
@onready var anim: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var body: Node2D = $Body
@onready var shadow: Node2D = $Shadow
@onready var coll: CollisionShape2D = $CollisionShape2D
@onready var nav: NavigationAgent2D = $NavigationRegion

# 状态和变量
enum State { CREAT, IDLE, MOVE, ATK, DEATH, HIT }
var current_state: State = State.CREAT
var timer: Timer
var attack_timer: Timer
var is_alive: bool = true

func _ready() -> void:
	# 延迟初始化，确保玩家位置可用
	await get_tree().create_timer(0.1).timeout
	
	# 检查玩家位置
	var player_pos = GameManager.getPlayerPos()
	if player_pos == Vector2.ZERO:
		push_error("GameManager.getPlayerPos() returned (0, 0)! Ensure player is initialized.")
		queue_free()
		return

	
	# 初始化计时器
	timer = Timer.new()
	timer.wait_time = idle_interval
	timer.one_shot = true
	timer.timeout.connect(_on_idle_timer_timeout)
	add_child(timer)
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# 播放创建动画
	if current_state == State.CREAT:
		anim.play("create")
		await anim.animation_finished
		current_state = State.IDLE

func _physics_process(delta: float) -> void:
	if not is_alive or current_state == State.CREAT:
		return
	
	# 检查玩家位置有效性
	var player_pos = GameManager.getPlayerPos()
	if player_pos == Vector2.ZERO:
		print("Warning: GameManager.getPlayerPos() returned (0, 0) in _physics_process!")
		return
		
	if  velocity.x <= 0:
		body.scale.x = -1
	else:
		body.scale.x = 1
	print('12121212 ',is_facing_target(),velocity)
	
	match current_state:
		State.IDLE:
			_handle_idle()
		State.MOVE:
			_handle_move()
		State.ATK:
			_handle_attack()
		State.HIT:
			_handle_hit()
		State.DEATH:
			_handle_death()
	
	# 调试：输出状态和速度
	#print("State: ", State.keys()[current_state], ", Velocity: ", velocity, ", Target: ", nav.target_position)
	
	move_and_slide()
	change_anim()

func _handle_idle() -> void:
	var distance_sq = global_position.distance_squared_to(GameManager.getPlayerPos())
	# TODO 后续修改 通过area2D检测进入范围后就进行攻击
	if distance_sq < attack_range * attack_range:
		current_state = State.ATK
	elif distance_sq < detection_range * detection_range:
		current_state = State.MOVE  # 直接进入MOVE，测试移动效果
	else:
		velocity = Vector2.ZERO
		if timer.is_stopped():
			timer.start()

func _on_idle_timer_timeout() -> void:
	if current_state == State.IDLE:
		current_state = State.MOVE

func _handle_move() -> void:
	var player_pos = GameManager.getPlayerPos()
	var distance_sq = global_position.distance_to(player_pos)
	if distance_sq < attack_range:
		current_state = State.ATK
	elif distance_sq > detection_range:
		current_state = State.IDLE
	else:
		nav.target_position = player_pos
		if nav.is_navigation_finished():
			velocity = Vector2.ZERO
			current_state = State.IDLE
			print("Navigation finished, no path to player at ", player_pos)
			return
		var next_pos = nav.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity = direction * speed

func _handle_attack() -> void:
	velocity = Vector2.ZERO
	var distance_sq = global_position.distance_squared_to(GameManager.getPlayerPos())
	if distance_sq > attack_range * attack_range:
		current_state = State.MOVE
	elif attack_timer.is_stopped():
		perform_attack()
		attack_timer.start()

func perform_attack() -> void:
	anim.play("attack")
	print("Enemy attacks!")  # 替换为你的攻击逻辑

func _on_attack_timer_timeout() -> void:
	if current_state == State.ATK:
		pass

func _handle_hit() -> void:
	velocity = Vector2.ZERO
	anim.play("hit")
	await anim.animation_finished
	if is_alive:
		current_state = State.IDLE

func _handle_death() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	anim.play("death")
	await anim.animation_finished
	timer.timeout.disconnect(_on_idle_timer_timeout)
	attack_timer.timeout.disconnect(_on_attack_timer_timeout)
	queue_free()

func is_facing_target() -> bool:
	var dir_to_target = (GameManager.getPlayerPos() - global_position).normalized()
	var facing_dir = body.transform.x.normalized()
	var dot = facing_dir.dot(dir_to_target)
	return dot >= 0.7

func change_anim() -> void:
	if not is_alive:
		return
	match current_state:
		State.IDLE:
			if anim.animation != "idle":
				anim.play("idle")
		State.MOVE:
			if anim.animation != "move":
				anim.play("move")
		State.ATK:
			if anim.animation != "attack":
				anim.play("attack")
		State.HIT:
			if anim.animation != "hit":
				anim.play("hit")
		State.DEATH:
			if anim.animation != "death":
				anim.play("death")

func take_damage() -> void:
	if is_alive:
		current_state = State.HIT
		# 替换为你的生命值逻辑
		# health -= damage
		# if health <= 0:
		#     current_state = State.DEATH
