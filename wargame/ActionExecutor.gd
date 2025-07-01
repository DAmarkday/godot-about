# ===============================
# ActionExecutor 类定义
# ===============================
class_name ActionExecutor
extends Node

signal action_executed(action: BattleAction)

var battle_grid: BattleGrid

func _init(grid: BattleGrid):
	battle_grid = grid

func execute_action(action: BattleAction) -> bool:
	match action.action_type:
		BattleAction.ActionType.ATTACK:
			return _execute_attack(action)
		BattleAction.ActionType.MOVE:
			return _execute_move(action)
		BattleAction.ActionType.DEFEND:
			return _execute_defend(action)
		BattleAction.ActionType.WAIT:
			return _execute_wait(action)
		_:
			print("未实现的行动类型: ", action.action_type)
			return false

func _execute_attack(action: BattleAction) -> bool:
	if not action.actor or not action.target:
		return false
	
	if not action.target.is_alive:
		return false
	
	var actor_pos = Vector2i(action.actor.position_x, action.actor.position_y)
	var target_pos = Vector2i(action.target.position_x, action.target.position_y)
	
	if battle_grid.get_distance(actor_pos, target_pos) > 1:
		print("目标距离太远，无法攻击")
		return false
	
	var damage = action.target.take_damage(action.actor.attack_power)
	print("%s 攻击 %s，造成 %d 点伤害" % [action.actor.unit_name, action.target.unit_name, damage])
	
	action_executed.emit(action)
	return true

func _execute_move(action: BattleAction) -> bool:
	if not action.actor:
		return false
	
	var success = battle_grid.move_unit(action.actor, action.target_position)
	if success:
		print("%s 移动到 (%d, %d)" % [action.actor.unit_name, action.target_position.x, action.target_position.y])
		action_executed.emit(action)
	else:
		print("移动失败：位置无效或被占用")
	
	return success

func _execute_defend(action: BattleAction) -> bool:
	if not action.actor:
		return false
	
	print("%s 采取防御姿态" % action.actor.unit_name)
	action_executed.emit(action)
	return true

func _execute_wait(action: BattleAction) -> bool:
	if not action.actor:
		return false
	
	print("%s 等待" % action.actor.unit_name)
	action_executed.emit(action)
	return true
