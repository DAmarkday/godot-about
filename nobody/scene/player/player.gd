extends CharacterBody2D
class_name Player

@export var SPEED = 270.0 

@onready var anim = $Body/AnimatedSprite2D
@onready var body:Node2D = $Body
@onready var weapon_node:Node2D = $Body/WeaponNode
#@onready var hand_nodeL:Node2D = $Body/HandNodeL
@onready var hand_nodeR:Node2D = $Body/HandNodeR

var _current_anim = 'down_'
var _last_direction := Vector2.ZERO

var curWeapon = null;
var isFlip = false;
	
func _ready():
	pass

var last_mouse_pos = Vector2.ZERO  # 记录上一次鼠标位置
var mouse_move_threshold = 10.0  # 鼠标移动最小距离阈值
var min_distance_threshold = 8.0
func _input(event):
	#var mouse_position = get_global_mouse_position()
	#var bp= weapon_node.get_child(0).getBollPointPos()
	#var temp= mouse_position - bp
	#var angle = atan2(temp.y, temp.x)
	#
	#weapon_node.global_rotation = angle
	pass
	#if event is InputEventMouseMotion:
		## 枪口和鼠标的差值与x正方向的夹角就是武器节点(手柄处)的全局旋转角度
		#var mouse_position = get_global_mouse_position()
		#var bp= weapon_node.get_child(0).getBollPointPos()
		#var temp= mouse_position - bp
		#var angle = atan2(temp.y, temp.x)
		#
		#weapon_node.global_rotation = angle
		#if mouse_position.distance_to(last_mouse_pos) > mouse_move_threshold:
			#last_mouse_pos = mouse_position
			#var direction = mouse_position - global_position
			#if direction.length() > min_distance_threshold:
				#var to_mouse = mouse_position - global_position
				#
				##if to_mouse.length()<20:
					##mouse_position = mouse_position.normalized() * 10000
	#
				#update_animation_and_facing(mouse_position)
				##last_direction = direction.normalized()
				##update_animation(last_direction)
func _physics_process(delta: float) -> void:
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("move_left","move_right")
	dir.y = Input.get_axis("move_up","move_down")
	
	velocity = dir.normalized() *SPEED
	move_and_slide()
	
	var mouse_position = get_global_mouse_position()
	var bp= weapon_node.get_child(0).getBollPointPos()
	var temp= mouse_position - bp
	var angle = atan2(temp.y, temp.x)
	
	weapon_node.global_rotation = angle
	
	# 更新动画和朝向
	update_animation_and_facing(mouse_position)
	
	# 射击逻辑
	if Input.is_action_pressed("fire") and curWeapon:
		curWeapon.shoot()


func _process(delta: float) -> void:	
	
	#var mouse_position = get_global_mouse_position()
	#var to_mouse = mouse_position - global_position
	#if to_mouse.length()<20:
		#mouse_position = mouse_position.normalized() * 10000
	#
	#update_animation_and_facing(mouse_position,delta)
	#weapon_node.look_at(mouse_position)
	# 枪口和鼠标的差值与x正方向的夹角就是武器节点(手柄处)的全局旋转角度
	#var mouse_position = get_global_mouse_position()
	#var bp= weapon_node.get_child(0).getBollPointPos()
	#var temp= mouse_position - bp
	#var angle = atan2(temp.y, temp.x)
	#
	#weapon_node.global_rotation = angle
	#if mouse_position.distance_to(last_mouse_pos) > mouse_move_threshold:
		#last_mouse_pos = mouse_position
		#var direction = mouse_position - global_position
		#if direction.length() > min_distance_threshold:
			#var to_mouse = mouse_position - global_position
			
			#if to_mouse.length()<20:
				#mouse_position = mouse_position.normalized() * 10000

			#last_direction = direction.normalized()
			#update_animation(last_direction)
	#update_animation_and_facing(mouse_position)

	
	#if Input.is_action_pressed("fire"):
		## 计时器归零时执行操作并重置计时器
		#if(curWeapon):
			#curWeapon.shoot()	
	#
	pass

	
func update_animation_and_facing(mouse_position):		
	var to_mouse = mouse_position - global_position
	# 计算角度（弧度）
	var angle_rad = to_mouse.angle()
	
	# 转换为角度（可选）
	var angle_deg = rad_to_deg(angle_rad)
	#print('`to_mouse`',to_mouse,angle_deg,to_mouse.length())
	
	
	# 确保角度在 0-360 范围内
	#angle_deg = fmod(angle_deg + 360, 360)
	#print("angle_deg", angle_deg)
	
	# 输出角度（用于调试）

	# 更新角色朝向
	weapon_node.position = Vector2(0,0)
	

	weapon_node.visible = false
	
	#hand_nodeL.visible = false
	hand_nodeR.visible = false
	
	#weapon_node.reparent(hand_nodeR)
	weapon_node.position =hand_nodeR.position
	
	var weaponNodeDeg = weapon_node.transform.get_rotation()
	var weaponNodeRota = rad_to_deg(weaponNodeDeg)
	#print("weaponNodeRota is ",weaponNodeRota)
	# 控制角色翻转
	var target_scale_x = body.scale.x
	
	#控制角色动画翻转 要求是
	#从鼠标在人物左方到右方超过 70°时才还原翻转
	#从鼠标在人物右方到左方超过 110°时才翻转
	var realRotate = 0
	if isFlip == false:
		realRotate = weaponNodeRota
		if weaponNodeRota>=0:
			if (realRotate >110):
				isFlip = true
				if target_scale_x != -1:
					#body.scale.x = -1
					target_scale_x=-1
		else:
			if (realRotate <-110):
				isFlip = true
				if target_scale_x != -1:
					#body.scale.x = -1
					target_scale_x=-1
	else:
		if weaponNodeRota>=0:
			realRotate =  180 - weaponNodeRota 
			if realRotate <70:
				isFlip = false
				if target_scale_x != 1:
					#body.scale.x = 1
					target_scale_x=1
				
		else:
			realRotate = -(180- abs(weaponNodeRota) )
			if realRotate >-70:
				isFlip = false
				if target_scale_x != 1:
					#body.scale.x = 1
					target_scale_x=1
					
	body.scale.x = target_scale_x
	
	if -20 <=angle_deg and angle_deg<60:
		#右下角 朝右
		hand_nodeR.visible = true
		#weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 手 枪 身体
		#weapon_node.z_index = -1
		#hand_nodeR.z_index = 1
		weapon_node.move_to_front()
		hand_nodeR.move_to_front()
		
		
		if velocity == Vector2.ZERO:
			_current_anim = 'lr_idle'
		else:
			_current_anim = 'lr_move'
		pass
	elif 60 <=angle_deg and angle_deg <120:
		#正下方 朝下
		hand_nodeR.visible = true
		#weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 手 枪 身体
		#weapon_node.z_index = -1
		#hand_nodeR.z_index = 1
		weapon_node.move_to_front()
		hand_nodeR.move_to_front()
		if velocity == Vector2.ZERO:
			_current_anim = 'down_idle'
		else:
			_current_anim = 'down_move'
		pass
	elif (120 <=angle_deg and angle_deg <180) or ( -180<= angle_deg and angle_deg < -160):
		#左下方 朝左
		hand_nodeR.visible = true
		#weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 手 枪 身体
		#weapon_node.z_index = -1
		#hand_nodeR.z_index = 1
		weapon_node.move_to_front()
		hand_nodeR.move_to_front()
		if velocity == Vector2.ZERO:
			_current_anim = 'lr_idle'
		else:
			_current_anim = 'lr_move'
		pass
	elif -160 <=angle_deg and angle_deg <-120:
		#左上方 朝左上
		hand_nodeR.visible = true
		#weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 身体 手 枪 
		#anim.z_index = 1
		#weapon_node.z_index = -1
		#hand_nodeR.z_index = 0
		hand_nodeR.move_to_front()
		anim.move_to_front()
		if velocity == Vector2.ZERO:
			_current_anim = 'backlr_idle'
		else:
			_current_anim = 'backlr_move'
		pass
	elif -120 <=angle_deg and angle_deg <-60:
		#上方 朝上
		hand_nodeR.visible = true
		#weapon_node.reparent(hand_nodeR)
		## 从上到下的渲染顺序是 身体 手 枪 
		#anim.z_index = 1
		#weapon_node.z_index = -1
		#hand_nodeR.z_index = 0
		hand_nodeR.move_to_front()
		anim.move_to_front()
		if velocity == Vector2.ZERO:
			_current_anim = 'up_idle'
		else:
			_current_anim = 'up_move'
		pass
	elif -60 <=angle_deg and angle_deg <-20:
		#右上方 朝右上
		#朝右
		hand_nodeR.visible = true
		#weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 身体 手 枪 
		#anim.z_index = 1
		#hand_nodeR.z_index = 0
		#weapon_node.z_index = -1
		hand_nodeR.move_to_front()
		anim.move_to_front()
		if velocity == Vector2.ZERO:
			_current_anim = 'backlr_idle'
		else:
			_current_anim = 'backlr_move'
		pass
	
	anim.play(_current_anim)	
	#await anim.animation_finished 
	#await anim.
	#await get_tree().process_frame
	weapon_node.visible = true

func set_single_hand_weapon(node:Node2D):
	curWeapon = node
	weapon_node.add_child(node)
