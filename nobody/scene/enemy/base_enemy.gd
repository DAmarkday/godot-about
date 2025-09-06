extends CharacterBody2D

class_name BaseEnemy

@export var speed = 25
@onready var anim = $Body/AnimatedSprite2D
@onready var body = $Body
@onready var shadow = $Shadow 
@onready var coll =$CollisionShape2D
enum State {
	IDLE,
	MOVE,
	ATK,
	DEATH,
	HIT
}

var current_state = State.IDLE
var current_player = null
