# ===============================
# TurnManager 类定义
# ===============================
class_name TurnManager
extends Node

signal turn_started(unit: BattleUnit)
signal turn_ended(unit: BattleUnit)
signal round_started(round_number: int)
signal round_ended(round_number: int)

var battle_units: Array[BattleUnit] = []
var current_turn_index: int = 0
var current_round: int = 1
var is_battle_active: bool = false

func initialize_battle(units: Array[BattleUnit]):
	battle_units = units.duplicate()
	_sort_units_by_speed()
	current_turn_index = 0
	current_round = 1
	is_battle_active = true
	
	round_started.emit(current_round)
	_start_next_turn()

func _sort_units_by_speed():
	battle_units.sort_custom(func(a: BattleUnit, b: BattleUnit): 
		return a.speed > b.speed
	)

func get_current_unit() -> BattleUnit:
	if battle_units.is_empty():
		return null
	return battle_units[current_turn_index]

func end_current_turn():
	if not is_battle_active:
		return
	
	var current_unit = get_current_unit()
	if current_unit:
		turn_ended.emit(current_unit)
	
	current_turn_index += 1
	
	if current_turn_index >= battle_units.size():
		_end_round()
	else:
		_start_next_turn()

func _start_next_turn():
	while current_turn_index < battle_units.size():
		var unit = battle_units[current_turn_index]
		if unit.is_alive:
			turn_started.emit(unit)
			return
		current_turn_index += 1
	
	_end_round()

func _end_round():
	round_ended.emit(current_round)
	current_round += 1
	current_turn_index = 0
	
	battle_units = battle_units.filter(func(unit): return unit.is_alive)
	
	if battle_units.size() > 0:
		round_started.emit(current_round)
		_start_next_turn()
	else:
		is_battle_active = false
