extends CharacterBody2D
class_name Player

@export var SPEED = 150.0 


@onready var anim = $Body/AnimatedSprite2D
@onready var body = $Body
@onready var weapon_node:Node2D = $Body/WeaponNode
#@onready var hand_nodeL:Node2D = $Body/HandNodeL
@onready var hand_nodeR:Node2D = $Body/HandNodeR
@onready var camera=$Camera2D

var _current_anim = 'down_'
var _last_direction := Vector2.ZERO

var curWeapon = null;
var isFlip = false;
	
func _ready():
	pass
	
func _physics_process(delta: float) -> void:	
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("move_left","move_right")
	dir.y = Input.get_axis("move_up","move_down")
	
	
	velocity = dir.normalized() *SPEED
	
	var mouse_position = get_global_mouse_position()
	update_animation_and_facing(mouse_position)
	weapon_node.look_at(mouse_position)
	
	move_and_slide()
	
	if Input.is_action_pressed("fire"):
			# 计时器归零时执行操作并重置计时器
		if(curWeapon):
			curWeapon.shoot(Vector2(mouse_position.x,mouse_position.y))	
	
func update_animation_and_facing(mouse_position):		
	var to_mouse = mouse_position - global_position
	
	# 计算角度（弧度）
	var angle_rad = to_mouse.angle()
	
	# 转换为角度（可选）
	var angle_deg = rad_to_deg(angle_rad)
	
	
	# 确保角度在 0-360 范围内
	#angle_deg = fmod(angle_deg + 360, 360)
	#print("angle_deg", angle_deg)
	
	# 输出角度（用于调试）

	# 更新角色朝向
	weapon_node.position = Vector2(0,0)
	
	weapon_node.z_index = 0
	anim.z_index= 0
	#hand_nodeL.z_index = 0
	hand_nodeR.z_index = 0
	
	#hand_nodeL.visible = false
	hand_nodeR.visible = false
	
	var weaponNodeDeg = weapon_node.transform.get_rotation()
	var weaponNodeRota = rad_to_deg(weaponNodeDeg)
	print("weaponNodeRota is ",weaponNodeRota)
	#if weaponNodeRota <=120 and weaponNodeRota >=-120:
		##isFlip = false
		#if body.scale.x != 1:
			#body.scale.x = 1
	#else :
		#if body.scale.x != -1:
			#body.scale.x = -1
			##isFlip = true
	
	#控制角色动画翻转 要求是
	#从鼠标在人物左方到右方超过 70°时才还原翻转
	#从鼠标在人物右方到左方超过 110°时才翻转
	var realRotate = 0
	if isFlip == false:
		realRotate = weaponNodeRota
		if weaponNodeRota>=0:
			if (realRotate >110):
				isFlip = true
				if body.scale.x != -1:
					body.scale.x = -1
		else:
			if (realRotate <-70):
				isFlip = true
				if body.scale.x != -1:
					body.scale.x = -1
	else:
		if weaponNodeRota>=0:
			realRotate =  180 - weaponNodeRota 
			if realRotate <70:
				isFlip = false
				if body.scale.x != 1:
					body.scale.x = 1
				
		else:
			realRotate = -(180- abs(weaponNodeRota) )
			if realRotate >-70:
				isFlip = false
				if body.scale.x != 1:
					body.scale.x = 1
	
	if -20 <=angle_deg and angle_deg<60:
		#右下角 朝右
		hand_nodeR.visible = true
		weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 手 枪 身体
		weapon_node.z_index = -1
		hand_nodeR.z_index = 1
		if velocity == Vector2.ZERO:
			_current_anim = 'lr_idle'
		else:
			_current_anim = 'lr_move'
		anim.play(_current_anim)	
		pass
	elif 60 <=angle_deg and angle_deg <120:
		#正下方 朝下
		hand_nodeR.visible = true
		weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 手 枪 身体
		weapon_node.z_index = -1
		hand_nodeR.z_index = 1
		if velocity == Vector2.ZERO:
			_current_anim = 'down_idle'
		else:
			_current_anim = 'down_move'
		anim.play(_current_anim)	
		pass
	elif (120 <=angle_deg and angle_deg <180) or ( -180<= angle_deg and angle_deg < -160):
		#左下方 朝左
		hand_nodeR.visible = true
		weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 手 枪 身体
		weapon_node.z_index = -1
		hand_nodeR.z_index = 1
		if velocity == Vector2.ZERO:
			_current_anim = 'lr_idle'
		else:
			_current_anim = 'lr_move'
		anim.play(_current_anim)	
		pass
	elif -160 <=angle_deg and angle_deg <-120:
		#左上方 朝左上
		hand_nodeR.visible = true
		weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 身体 手 枪 
		anim.z_index = 1
		weapon_node.z_index = -1
		hand_nodeR.z_index = 0
		if velocity == Vector2.ZERO:
			_current_anim = 'backlr_idle'
		else:
			_current_anim = 'backlr_move'
		anim.play(_current_anim)	
		pass
	elif -120 <=angle_deg and angle_deg <-60:
		#上方 朝上
		hand_nodeR.visible = true
		weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 身体 手 枪 
		anim.z_index = 1
		weapon_node.z_index = -1
		hand_nodeR.z_index = 0
		if velocity == Vector2.ZERO:
			_current_anim = 'up_idle'
		else:
			_current_anim = 'up_move'
		anim.play(_current_anim)	
		pass
	elif -60 <=angle_deg and angle_deg <-20:
		#右上方 朝右上
		#朝右
		hand_nodeR.visible = true
		weapon_node.reparent(hand_nodeR)
		# 从上到下的渲染顺序是 身体 手 枪 
		anim.z_index = 1
		hand_nodeR.z_index = 0
		weapon_node.z_index = -1
		if velocity == Vector2.ZERO:
			_current_anim = 'backlr_idle'
		else:
			_current_anim = 'backlr_move'
		anim.play(_current_anim)	
		pass

func set_single_hand_weapon(node:Node2D):
	curWeapon = node
	weapon_node.add_child(node)
