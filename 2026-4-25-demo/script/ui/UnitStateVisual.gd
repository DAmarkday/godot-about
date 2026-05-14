## UnitStateVisual.gd
## 棋子行动状态视觉反馈管理器。
## 监听信号，根据棋子行动状态修改其外观（透明度/颜色）。
class_name UnitStateVisual extends Node

## UnitManager 引用，用于获取玩家棋子列表（通过 setup 注入）
var _unit_manager: UnitManager = null

func _ready() -> void:
	# 监听棋子移动、攻击、玩家回合开始、棋子死亡信号
	EventBus.unit_moved.connect(_on_unit_moved)
	EventBus.attack_performed.connect(_on_attack_performed)
	EventBus.player_turn_started.connect(_on_player_turn_started)
	EventBus.unit_died.connect(_on_unit_died)
	pass

## 注入 UnitManager 引用，用于回合开始时重置所有玩家棋子外观
## unit_manager: UnitManager 节点引用
func setup(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager
	
## 响应棋子移动信号：若未攻击则应用半透明效果（表示还能攻击）
## unit:  移动的棋子节点
## _from: 起始格子坐标（未使用）
## _to:   目标格子坐标（未使用）
func _on_unit_moved(unit, _from, _to) -> void:
	if not unit.has_attacked:
		unit.modulate.a = 0.6
		
## 响应攻击信号：对攻击者应用灰色效果（表示行动结束）
## attacker: 发起攻击的棋子节点
## _target:  被攻击的棋子节点（未使用）
## _damage:  伤害值（未使用）
func _on_attack_performed(attacker, _target, _damage) -> void:
	attacker.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
## 响应玩家回合开始信号：重置所有玩家棋子的外观为默认白色
## _turn_number: 当前回合数（未使用）
func _on_player_turn_started(_turn_number: int) -> void:
	if _unit_manager == null:
		return
	# 遍历所有玩家棋子，恢复默认外观
	for unit in _unit_manager.get_player_units():
		unit.modulate = Color.WHITE

## 响应棋子死亡信号：恢复默认外观（queue_free 前）
## unit: 死亡的棋子节点
## _team: 所属阵营（未使用）
func _on_unit_died(unit, _team) -> void:
	if is_instance_valid(unit):
		unit.modulate = Color.WHITE
