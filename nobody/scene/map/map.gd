extends Node2D

const _player = preload("res://scene/player/Player.tscn")

func _ready():
	var instance = _player.instantiate()
	add_child(instance)
	pass # Replace with function body.

func _process(delta):
	pass
