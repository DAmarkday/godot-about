extends Node2D
class_name BaseBullet

@export var speed = 500
@export var dir = Vector2.ZERO

var _tick = 0
var velocity = Vector2(500, 0)
# physic默认在项目设置里是60帧，process就是实际游戏帧率
func _physics_process(delta):
	global_position += velocity*delta
	_tick+=delta
	if Engine.get_physics_frames() % 20:
		if _tick>=3:
			queue_free()
			pass

# Called when the node enters the scene tree for the first time.
func _ready():
	if(dir !=Vector2.ZERO):
		velocity=dir *  speed

func handle_hurt(body: Node2D):
	#print(' handle_hurt is  ',body)
	if body:
		body.take_damage(1)
		#Game.damage(Game.player,body)
		set_physics_process(false)
		
		#var ins = _pre_hit_effect.instantiate()
		#ins.global_position = global_position
		#Game.map.add_child(ins)
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	print('xxxx',body)
	if body is BaseEnemy:
		handle_hurt(body)
		queue_free()


	pass # Replace with function body.
