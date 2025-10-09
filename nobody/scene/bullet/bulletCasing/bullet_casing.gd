
extends CharacterBody2D
class_name BulletCasing
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@export var gravity: float = 98

var motion: Vector2 = Vector2.ZERO # 初始速度
var dir:Vector2 = get_random_unit_vector();
var init_x_speed_counts = 50
var init_y_speed_counts = 150
var shadow = preload("res://scene/bullet/bulletCasing/bulletCasingShadow.tscn")

var caculate_top_point:Vector2 = Vector2.ZERO
var caculate_land_point:Vector2= Vector2.ZERO
var is_cur_created_landing:bool = false
var shell_shadow_instance:BulletCasingShadow;
var init_shell_shadow_pos:Vector2
var landing:bool = false
var max_bounces: int = 3  # 最大反弹次数 1次代表不反弹
var bounce_count: int = 0  # 当前反弹次数
func ani_play():
	var w=1
	anim.frame  = w

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
	
func get_random_unit_vector(random_range:Array=[-130, -150]) -> Vector2:
	# 生成 0 到 180 度的随机角度（转换为弧度）
	var angle_degrees = randf_range(random_range[0], random_range[1])
	var angle_radians = deg_to_rad(angle_degrees)
	
	# 使用 cos 和 sin 计算单位向量的 x 和 y 分量
	var unit_vector = Vector2(cos(angle_radians), sin(angle_radians))
	
	return unit_vector
	
func update_trajectory(y_range:Array=[-20, 0]) -> void:
	# 计算抛物线的顶点和着地点
	var result = Tools.calculate_trajectory_points(global_position, motion, gravity, y_range)
	#print('1222222is ',motion)
	caculate_top_point = result.apex
	caculate_land_point = result.landing
	#print('12121 is ',result)
	
	is_cur_created_landing = true
	
	# 计算生成影子的移动公式
	shell_shadow_instance.caculate_Y(caculate_land_point, init_shell_shadow_pos, global_position.x)
	shell_shadow_instance.move(global_position.x)
	# 生成最高点和着地点的标识
	create_circle(caculate_top_point, 1, Color.GREEN)
	create_circle(caculate_land_point, 1, Color.RED)

func stop_motion() -> void:
	set_physics_process(false)
	motion = Vector2.ZERO
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.5).timeout
	# 播放淡出动画
	var fade_time: float = 2.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 0.7), fade_time)
	tween.parallel().tween_property(self, "modulate:a", 0.0, fade_time)
	shell_shadow_instance.recycle_ani()
	tween.tween_callback(func(): 
		queue_free()
		shell_shadow_instance.queue_free()
	)  # 通知 


func _ready() -> void:
	motion = Vector2(dir.x*init_x_speed_counts,dir.y* init_y_speed_counts)
	velocity = motion
	
	# 生成影子
	var shad=shadow.instantiate()
	GameManager.getMapInstance().addEntityToViewer(shad)
	# 影子生成在人物影子中
	init_shell_shadow_pos = GameManager.getPlayerPos()
	shad.global_position = init_shell_shadow_pos
	shad.mapping_shell_instance = self
	shell_shadow_instance = shad
		
	update_trajectory([-50,-30])
	
func _physics_process(delta):
	#没有落地
	#弹壳移动()
	if not landing:
		# 弹壳模拟重力
		motion.y += gravity * delta 
		velocity = motion
		move_and_slide()
		
		shell_shadow_instance.move(global_position.x)
		
		
		# 检查是否到达落地点
		if global_position.y >=shell_shadow_instance.global_position.y and bounce_count < max_bounces:
			global_position = caculate_land_point
			#print("121212 is ",caculate_land_point)
			shell_shadow_instance.global_position = caculate_land_point
			bound()
	
	# 检查是否停止
	if bounce_count >= max_bounces:
		stop_motion()
	
func bound():
	landing = true
	bounce_count += 1
	#已经落地
	#print("bound 触发")
	
	#清空落地点
	is_cur_created_landing = false
	caculate_top_point =  Vector2.ZERO
	caculate_land_point = Vector2.ZERO
	init_shell_shadow_pos = global_position
	#反弹
	if bounce_count < max_bounces:
		motion.y = -0.7 * motion.y
		motion.x = 0.5 * motion.x
		landing = false
		
		update_trajectory([-50,-30])
	else:
		stop_motion()	
