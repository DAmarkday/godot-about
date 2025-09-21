extends Node2D

@export var gravity: float = 500.0  # 重力加速度（像素/秒²，下正）
@export var initial_horizontal_speed: float = 50.0  # 初始水平抛出速度（向射击方向相反）
@export var initial_vertical_speed: float = -150.0  # 初始垂直抛出速度（向上，负值）
@export var lifetime: float = 1.5  # 总存活时间
@export var rotation_speed_range: Vector2 = Vector2(2 * PI, 4 * PI)  # 旋转速度范围（弧度/秒）
@export var speed_scale_range: Vector2 = Vector2(0.8, 1.2)  # 速度缩放范围（随机变异）

var velocity: Vector2 = Vector2.ZERO
var is_flying: bool = false
var start_time: float = 0.0
var ground_y: float = 0.0  # 动态计算的地面 y 坐标
var rotation_speed: float = 0.0  # 运行时随机旋转速度

func setup(muzzle_position: Vector2, player_position: Vector2, player_direction: Vector2, distance: float = 50):
	global_position = muzzle_position
	rotation = randf_range(-PI/4, PI/4)  # 初始轻微随机旋转
	
	# 归一化射击方向
	var normalized_dir = player_direction.normalized()
	
	# 随机缩放速度
	var speed_scale = randf_range(speed_scale_range.x, speed_scale_range.y)
	
	# 水平速度：向射击方向相反
	velocity.x = -normalized_dir.x * initial_horizontal_speed * speed_scale
	velocity.y = initial_vertical_speed * speed_scale  # 向上（负值）
	
	# 计算落点和 ground_y
	var is_horizontal = abs(normalized_dir.y) < 0.1  # 判断是否接近水平（y分量小）
	if is_horizontal:
		# 水平射击：落点在玩家 y 坐标
		ground_y = player_position.y
	else:
		# 非水平射击：落点沿射击反方向偏移指定 distance
		var land_position = player_position - normalized_dir * distance
		ground_y = land_position.y  # 落点 y 坐标作为 ground_y
	
	# 随机旋转速度
	rotation_speed = randf_range(rotation_speed_range.x, rotation_speed_range.y) * (-1 if randf() < 0.5 else 1)
	
	is_flying = true
	start_time = Time.get_unix_time_from_system()

func _physics_process(delta: float) -> void:
	if is_flying:
		# 应用重力（y正向下）
		velocity.y += gravity * delta
		global_position += velocity * delta  # 更新全局位置
		
		# 旋转
		rotation += rotation_speed * delta
		
		# 检查是否落地（y >= ground_y）
		if global_position.y >= ground_y:
			is_flying = false
			velocity = Vector2.ZERO
			
			# 落地后动画：缩放 + 淡出
			var time_passed = Time.get_unix_time_from_system() - start_time
			var fade_time = max(0.3, lifetime - time_passed)  # 确保至少0.3秒淡出
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.7, 0.7), fade_time)
			tween.parallel().tween_property(self, "modulate:a", 0.0, fade_time)
			tween.tween_callback(func(): emit_signal("finished"))  # 通知 CasingManager 回收
		
		# 超时检查
		if Time.get_unix_time_from_system() - start_time > lifetime:
			is_flying = false
			emit_signal("finished")  # 通知回收

# 添加信号，用于通知 CasingManager 回收
signal finished

func reset():
	is_flying = false
	velocity = Vector2.ZERO
	start_time = 0.0
	rotation = 0.0
	scale = Vector2(1, 1)
	modulate.a = 1.0
