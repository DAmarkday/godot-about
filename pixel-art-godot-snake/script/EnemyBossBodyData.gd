extends Resource
class_name EnemyBossBodyData

@export var max_hp = 10 

var current_hp:
	set(_value):
		if current_hp and current_hp - _value !=0:
			on_hit.emit(current_hp - _value)
		current_hp = _value
		if current_hp <=0:
			on_death.emit()

signal on_death()
signal on_hit(damage)

func _init():
	current_hp = max_hp
