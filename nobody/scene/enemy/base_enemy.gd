extends CharacterBody2D

class_name BaseEnemy

@export var speed = 25
@onready var anim = $Body/AnimatedSprite2D
@onready var body = $Body
@onready var shadow = $Shadow 
@onready var coll =$CollisionShape2D
@onready var nav = $NavigationAgent2D
var movement_delta

enum State {
	IDLE,
	MOVE,
	ATK,
	DEATH,
	HIT
}

var current_state = State.IDLE
var current_player = null

func _physics_process(delta):
	movement_delta = speed
	var new_velocity: Vector2 = global_position.direction_to(GameManager.getPlayerPos()) * movement_delta	
	velocity = new_velocity
	move_and_slide()
	
	changeAnim()


func is_facing_target():
	var dir_to_target = (GameManager.getPlayerPos() - global_position).normalized()
	var facing_dir = transform.x.normalized()
	
	var dot = facing_dir.dot(dir_to_target)
	return dot >= (1-0.7)
	
func changeAnim():
	if velocity == Vector2.ZERO:
		anim.play("idle")
		current_state = State.IDLE
	else:
		anim.play("move")
		current_state = State.MOVE
		if !is_facing_target() and velocity.x <0:
			body.scale.x = -1 
		else:
			body.scale.x = 1
