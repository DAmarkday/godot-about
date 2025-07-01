# ===============================
# BattleGrid 类定义
# ===============================
class_name BattleGrid
extends Node2D

signal unit_moved(unit: BattleUnit, from_pos: Vector2i, to_pos: Vector2i)

@export var grid_width: int = 8
@export var grid_height: int = 6
@export var cell_size: int = 64

var grid: Array[Array] = []
var units: Dictionary = {}

func _ready():
	_init_grid()

func _init_grid():
	grid = []
	for y in grid_height:
		var row: Array[bool] = []
		for x in grid_width:
			row.append(false)
		grid.append(row)

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height

func is_position_occupied(pos: Vector2i) -> bool:
	return units.has(pos)

func place_unit(unit: BattleUnit, pos: Vector2i) -> bool:
	if not is_valid_position(pos) or is_position_occupied(pos):
		return false
	
	units[pos] = unit
	unit.position_x = pos.x
	unit.position_y = pos.y
	unit.position = Vector2(pos.x * cell_size, pos.y * cell_size)
	return true

func move_unit(unit: BattleUnit, to_pos: Vector2i) -> bool:
	var from_pos = Vector2i(unit.position_x, unit.position_y)
	
	if not is_valid_position(to_pos) or is_position_occupied(to_pos):
		return false
	
	units.erase(from_pos)
	units[to_pos] = unit
	unit.position_x = to_pos.x
	unit.position_y = to_pos.y
	unit.position = Vector2(to_pos.x * cell_size, to_pos.y * cell_size)
	
	unit_moved.emit(unit, from_pos, to_pos)
	return true

func get_unit_at(pos: Vector2i) -> BattleUnit:
	return units.get(pos, null)

func get_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)
