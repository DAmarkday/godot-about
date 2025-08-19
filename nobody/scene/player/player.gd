extends CharacterBody2D
class_name Player

@export var SPEED = 150.0 


@onready var anim = $Body/AnimatedSprite2D
@onready var body = $Body
@onready var weapon_node = $Body/WeaponNode
@onready var camera=$Camera2D

var _current_anim = 'down_'

func _ready():
	pass
