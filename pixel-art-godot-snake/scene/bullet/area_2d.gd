extends Area2D
class_name BaseBulletArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func clear():
	get_parent().deactive()
	
func isCanHurt():
	return get_parent().isBulletActive()
