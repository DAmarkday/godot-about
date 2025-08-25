extends CharacterBody2D
class_name Player

@export var SPEED = 800.0 


@onready var anim = $Body/AnimatedSprite2D
@onready var body = $Body
@onready var weapon_node = $Body/WeaponNode
@onready var camera=$Camera2D

var _current_anim = 'down_'
var _last_direction := Vector2.ZERO

func _ready():
	pass

func _physics_process(delta: float) -> void:	
	var dir = Vector2.ZERO
	dir.x = Input.get_axis("move_left","move_right")
	dir.y = Input.get_axis("move_up","move_down")
	
	velocity = dir.normalized() *SPEED
	
	update_animation_and_facing()
	
	move_and_slide()
	
func update_animation_and_facing():		
	var mouse_position = get_global_mouse_position()
	var to_mouse = mouse_position - global_position
	
	# 更新角色朝向
	if to_mouse.x >= 0:
		if body.scale.x != 1:
			body.scale.x = 1
			
		if to_mouse.y >= 0:
			#人物的右下角
			if abs(to_mouse.x) >=abs(to_mouse.y):
				#朝右
				if velocity == Vector2.ZERO:
					_current_anim = 'lr_idle'
				else:
					_current_anim = 'lr_move'
				anim.play(_current_anim)	
			else:
				#朝下
				if velocity == Vector2.ZERO:
					_current_anim = 'down_idle'
				else:
					_current_anim = 'down_move'
				anim.play(_current_anim)	
				pass
		else:
			#人物的右上角
			if abs(to_mouse.x) >=abs(to_mouse.y):
				#朝右
				if velocity == Vector2.ZERO:
					_current_anim = 'lr_idle'
				else:
					_current_anim = 'lr_move'
				anim.play(_current_anim)	
			else:
				#朝上
				if velocity == Vector2.ZERO:
					_current_anim = 'up_idle'
				else:
					_current_anim = 'up_move'
				anim.play(_current_anim)	
	else:
		if body.scale.x != -1:
			body.scale.x = -1
			
		if to_mouse.y >= 0:
			#人物的左下角
			if abs(to_mouse.x) >=abs(to_mouse.y):
				#朝左
				if velocity == Vector2.ZERO:
					_current_anim = 'lr_idle'
				else:
					_current_anim = 'lr_move'
				anim.play(_current_anim)	
			else:
				#朝下
				if velocity == Vector2.ZERO:
					_current_anim = 'down_idle'
				else:
					_current_anim = 'down_move'
				anim.play(_current_anim)	
		else:
			#人物的左上角
			if abs(to_mouse.x) >=abs(to_mouse.y):
				#朝左
				if velocity == Vector2.ZERO:
					_current_anim = 'lr_idle'
				else:
					_current_anim = 'lr_move'
				anim.play(_current_anim)	
			else:
				#朝上
				if velocity == Vector2.ZERO:
					_current_anim = 'up_idle'
				else:
					_current_anim = 'up_move'
				anim.play(_current_anim)	
	
	## 只有在方向变化时才更新动画
	#var new_anim = get_movement_direction()
	#if new_anim != _current_anim or velocity != _last_direction:
		#_current_anim = new_anim
		#_last_direction = velocity
		#anim.play(_current_anim)

#func get_movement_direction() -> String:
	#if velocity == Vector2.ZERO:
		#return "lr_"
	#
	#var angle := velocity.angle()
	#var degree := rad_to_deg(angle)
	#
	#if degree >= 45 and degree < 135:
		#return "down_"
	#elif degree >= -135 and degree < -45:
		#return "up_"
	#return "lr_"
