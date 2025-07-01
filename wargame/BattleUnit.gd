# ===============================
# BattleUnit 类定义
# ===============================
class_name BattleUnit
extends Node2D

signal health_changed(old_health: int, new_health: int)
signal unit_died
signal action_completed

@export var unit_name: String = "Unknown"
@export var max_health: int = 100
@export var attack_power: int = 20
@export var defense: int = 5
@export var speed: int = 10

var current_health: int
var is_alive: bool = true
var position_x: int = 0
var position_y: int = 0

func _ready():
	current_health = max_health

func take_damage(damage: int) -> int:
	var old_health = current_health
	var actual_damage = max(1, damage - defense)
	current_health = max(0, current_health - actual_damage)
	
	health_changed.emit(old_health, current_health)
	
	if current_health <= 0 and is_alive:
		is_alive = false
		unit_died.emit()
	
	return actual_damage

func heal(amount: int):
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	health_changed.emit(old_health, current_health)

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)
