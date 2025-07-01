# ===============================
# BattleSystem 类定义
# ===============================
class_name BattleSystem
extends Node

signal battle_started
signal battle_ended(winner_team: String)

var battle_grid: BattleGrid
var turn_manager: TurnManager
var action_executor: ActionExecutor
var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []

func _ready():
	_initialize_battle_system()

func _initialize_battle_system():
	battle_grid = BattleGrid.new()
	add_child(battle_grid)
	
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	action_executor = ActionExecutor.new(battle_grid)
	add_child(action_executor)
	
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	action_executor.action_executed.connect(_on_action_executed)

func start_battle(players: Array[BattleUnit], enemies: Array[BattleUnit]):
	player_units = players
	enemy_units = enemies
	
	_place_units_on_grid()
	
	var all_units = player_units + enemy_units
	turn_manager.initialize_battle(all_units)
	
	battle_started.emit()
	print("战斗开始！")

func _place_units_on_grid():
	for i in range(player_units.size()):
		var unit = player_units[i]
		var pos = Vector2i(1 + (i % 2), 1 + (i / 2))
		battle_grid.place_unit(unit, pos)
	
	for i in range(enemy_units.size()):
		var unit = enemy_units[i]
		var pos = Vector2i(6 + (i % 2), 1 + (i / 2))
		battle_grid.place_unit(unit, pos)

func execute_player_action(action: BattleAction) -> bool:
	var current_unit = turn_manager.get_current_unit()
	if current_unit != action.actor:
		print("不是该单位的回合")
		return false
	
	if action_executor.execute_action(action):
		turn_manager.end_current_turn()
		_check_battle_end()
		return true
	
	return false

func _on_turn_started(unit: BattleUnit):
	print("轮到 %s 行动" % unit.unit_name)
	
	if unit in enemy_units:
		_execute_ai_turn(unit)

func _on_turn_ended(unit: BattleUnit):
	print("%s 的回合结束" % unit.unit_name)

func _on_action_executed(action: BattleAction):
	print("行动执行完成")

func _execute_ai_turn(ai_unit: BattleUnit):
	await get_tree().create_timer(1.0).timeout
	
	var target = _find_nearest_enemy(ai_unit, player_units)
	if target:
		var ai_pos = Vector2i(ai_unit.position_x, ai_unit.position_y)
		var target_pos = Vector2i(target.position_x, target.position_y)
		var distance = battle_grid.get_distance(ai_pos, target_pos)
		
		if distance <= 1:
			var action = BattleAction.new(BattleAction.ActionType.ATTACK, ai_unit)
			action.target = target
			action_executor.execute_action(action)
		else:
			var move_pos = _find_move_position(ai_unit, target)
			if move_pos != Vector2i(-1, -1):
				var action = BattleAction.new(BattleAction.ActionType.MOVE, ai_unit)
				action.target_position = move_pos
				action_executor.execute_action(action)
			else:
				var action = BattleAction.new(BattleAction.ActionType.WAIT, ai_unit)
				action_executor.execute_action(action)
	
	turn_manager.end_current_turn()
	_check_battle_end()

func _find_nearest_enemy(unit: BattleUnit, enemies: Array[BattleUnit]) -> BattleUnit:
	var nearest: BattleUnit = null
	var min_distance = 999
	
	for enemy in enemies:
		if not enemy.is_alive:
			continue
		
		var distance = battle_grid.get_distance(
			Vector2i(unit.position_x, unit.position_y),
			Vector2i(enemy.position_x, enemy.position_y)
		)
		
		if distance < min_distance:
			min_distance = distance
			nearest = enemy
	
	return nearest

func _find_move_position(unit: BattleUnit, target: BattleUnit) -> Vector2i:
	var unit_pos = Vector2i(unit.position_x, unit.position_y)
	var target_pos = Vector2i(target.position_x, target.position_y)
	
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	for dir in directions:
		var test_pos = target_pos + dir
		if battle_grid.is_valid_position(test_pos) and not battle_grid.is_position_occupied(test_pos):
			return test_pos
	
	return Vector2i(-1, -1)

func _check_battle_end():
	var alive_players = player_units.filter(func(unit): return unit.is_alive)
	var alive_enemies = enemy_units.filter(func(unit): return unit.is_alive)
	
	if alive_players.is_empty():
		battle_ended.emit("Enemy")
		print("敌方获胜！")
	elif alive_enemies.is_empty():
		battle_ended.emit("Player")
		print("玩家获胜！")
