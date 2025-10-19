
extends CharacterBody2D
class_name BulletCasing
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@export var gravity: float = 98

var motion: Vector2 = Vector2.ZERO # 初始速度
var dir:Vector2 = Tools.get_random_unit_vector();
var init_x_speed_counts = 50
var init_y_speed_counts = 130
var shadow = preload("res://scene/bullet/bulletCasing/bulletCasingShadow.tscn")

var caculate_top_point:Vector2 = Vector2.ZERO
var caculate_land_point:Vector2= Vector2.ZERO
var is_cur_created_landing:bool = false
var shell_shadow_instance:BulletCasingShadow;
var init_shell_shadow_pos:Vector2
var landing:bool = false
var max_bounces: int = 4  # 最大反弹次数 1次代表不反弹
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


#第一次抛出时生成一个新的抛物线
func create_new_trajectory(y_range:Array=[5, 10]) -> void:
	# 计算抛物线的顶点和着地点
	var result = Tools.calculate_trajectory_points(global_position, motion, gravity, y_range)
	#print('1222222is ',motion)
	caculate_top_point = result.apex
	caculate_land_point = result.landing
	#print('12121 is ',result)
	
	is_cur_created_landing = true
	
	# 计算生成影子的移动公式
	shell_shadow_instance.caculate_Y(caculate_land_point, init_shell_shadow_pos, global_position.x)
	shell_shadow_instance.move(global_position.x,init_shell_shadow_pos)
	# 生成最高点和着地点的标识
	#create_circle(caculate_top_point, 1, Color.GREEN)
	#create_circle(caculate_land_point, 1, Color.RED)
	
##再次生成一个抛物线,着地点会根据首次生成的影子路径生成
#func use_shadow_path_to_create_land_pos():
	## 计算抛物线的顶点和着地点
	#var result = Tools.calculate_intersection_point(global_position, motion, gravity, shell_shadow_instance.k,shell_shadow_instance.b)
	#if result.landing == Vector2.ZERO:
		##说明没有交点 则不反弹
		#stop_motion()
		#print('xxxxxxxxxxxx')
		#pass
	#else:
		#caculate_top_point = result.apex
		#caculate_land_point = result.landing
		##print('12121 is ',result)
		#is_cur_created_landing = true
		#
		## 计算生成影子的移动公式
		#shell_shadow_instance.caculate_Y(caculate_land_point, init_shell_shadow_pos, global_position.x)
		#shell_shadow_instance.move(global_position.x)
		## 生成最高点和着地点的标识
		#create_circle(caculate_top_point, 1, Color.GREEN)
		#create_circle(caculate_land_point, 1, Color.RED)
		#
	#
	
	pass
#func update_trajectory(y_range:Array=[0, 20]) -> void:
	## 计算抛物线的顶点和着地点
	#var result = Tools.calculate_trajectory_points(global_position, motion, gravity, y_range)
	##print('1222222is ',motion)
	#caculate_top_point = result.apex
	#caculate_land_point = result.landing
	##print('12121 is ',result)
	#
	#is_cur_created_landing = true
	#
	## 计算生成影子的移动公式
	#shell_shadow_instance.caculate_Y(caculate_land_point, init_shell_shadow_pos, global_position.x)
	#shell_shadow_instance.move(global_position.x)
	## 生成最高点和着地点的标识
	#create_circle(caculate_top_point, 1, Color.GREEN)
	#create_circle(caculate_land_point, 1, Color.RED)

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
	# 影子生成在人物影子中
	init_shell_shadow_pos = GameManager.getPlayerPos()
	shad.global_position = init_shell_shadow_pos
	shad.mapping_shell_instance = self
	GameManager.getMapInstance().addEntityToViewer(shad)
	
	shell_shadow_instance = shad
		
	create_new_trajectory([5,10])
	
func _physics_process(delta):
	#没有落地
	#弹壳移动()
	if not landing:
		# 弹壳模拟重力
		motion.y += gravity * delta 
		velocity = motion
		move_and_slide()
		
		shell_shadow_instance.move(global_position.x,init_shell_shadow_pos)
		
		
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
		##motion.y = -2 * motion.y * pow(0.6,bounce_count)
		##motion.x =  1.2* motion.x * pow(0.7,bounce_count)
		#landing = false
		##
		### 竖直速度：反转并施加恢复系数 e=0.85（可调，0.8-0.9 模拟水面高弹性）
		##motion.y = -motion.y * 0.85
		#motion.y = -motion.y * (1.0 + 0.2 * bounce_count)  # 每次反弹竖直速度增加
		##motion.y = clamp(motion.y, -500, 0)  # 防止速度过大（根据游戏缩放调整）
		### 水平速度：施加稍大的衰减（模拟水面摩擦），避免增加
		#motion.x = motion.x * 0.7
		#var angle = atan2(motion.y, motion.x)
		#var random_angle_offset = deg_to_rad(randf_range(-5, 5))
		#angle += random_angle_offset
		#var speed = Vector2(motion.x, motion.y).length()
		#motion = Vector2(cos(angle), sin(angle)) * speed * 0.85  # 整体速度衰减
		
		#update_trajectory([10,20])
		#use_shadow_path_to_create_land_pos()
	
		# 限制速度，避免过小
		#motion.y = clamp(motion.y, -200, 0)
		#motion.x = clamp(motion.x, 20, 200)
		# 随机角度扰动
		#var angle = atan2(motion.y, motion.x)
		#var random_angle_offset = deg_to_rad(randf_range(-5, 5))
		#angle += random_angle_offset
		#var speed = Vector2(motion.x, motion.y).length()
		#motion = Vector2(cos(angle), sin(angle)) * speed
		var yk = 0.7
		var xk = 0.7
		if abs(motion.x)<10  and abs(motion.y) <10:
			stop_motion()
			return
		#elif abs(motion.y)<10:
			#xk = 0.3
		elif abs(motion.x)<10:
			yk = 0.3
		#elif abs(motion.y)<20:
			#xk = 0.6
		elif abs(motion.x)<20:
			yk = 0.6
		# 竖直速度：反转并衰减（e=0.8），弧形高度减小
		motion.y = dir.y* init_y_speed_counts * pow(yk,bounce_count)
		# 水平速度：轻微衰减，模拟摩擦
		motion.x = dir.x* init_x_speed_counts * pow(xk,bounce_count)
		
		landing = false
		create_new_trajectory([0,10])
	else:
		stop_motion()	
