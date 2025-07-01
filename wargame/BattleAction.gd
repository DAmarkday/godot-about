# ===============================
# BattleAction 类定义
# ===============================
class_name BattleAction
extends Resource

enum ActionType {
	ATTACK,
	MOVE,
	SKILL,
	WAIT,
	DEFEND
}

@export var action_type: ActionType
var actor: BattleUnit
var target: BattleUnit
@export var target_position: Vector2i
@export var skill_id: String = ""

func _init(type: ActionType = ActionType.WAIT, unit: BattleUnit = null):
	action_type = type
	actor = unit
