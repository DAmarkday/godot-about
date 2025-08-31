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
