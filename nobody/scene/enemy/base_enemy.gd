extends CharacterBody2D

class_name BaseEnemy

@export var speed = 15
@onready var anim = $Body/AnimatedSprite2D
@onready var body = $Body
@onready var shadow = $Shadow 
@onready var coll =$CollisionShape2D
@onready var nav = $NavigationAgent2D
var movement_delta

enum State {
	CREAT,
	IDLE,
	MOVE,
	ATK,
	DEATH,
	HIT
}

var current_state = State.CREAT
var current_player = null

func _ready() -> void:
	if current_state == State.CREAT:
		anim.play("create")
		await anim.animation_finished
		current_state = State.IDLE


func _physics_process(delta):
	if current_state == State.CREAT:
		return
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
