extends Area2D
class_name SnakeBossBodyArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	if area is BaseBulletArea && area.isCanHurt():
		set_physics_process(false)
		area.clear()
		get_parent().on_hit(5)
	pass # Replace with function body.
