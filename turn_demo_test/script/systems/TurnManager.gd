## TurnManager.gd
## 回合管理系统，负责控制玩家回合与敌方回合的切换、回合计数以及游戏结束判定。
## 继承 Node，作为场景树中的系统节点使用。
class_name TurnManager extends Node

# ─── 枚举 ────────────────────────────────────────────────────

## 回合状态枚举
enum TurnState {
	PLAYER_TURN,  # 玩家回合
	ENEMY_TURN,   # 敌方回合
	GAME_OVER     # 游戏结束
}

# ─── 成员变量 ────────────────────────────────────────────────

## 当前回合状态
var current_state: TurnState = TurnState.PLAYER_TURN

## 当前回合数（从 1 开始）
var turn_number: int = 0

## 棋子管理器引用（用于重置行动点）
var _unit_manager: UnitManager = null


# ─── 生命周期 ────────────────────────────────────────────────

func _ready() -> void:
	# 监听胜负信号，自动触发游戏结束流程
	# 注意：end_game 内部会检查 GAME_OVER 状态，防止无限循环
	EventBus.battle_won.connect(_on_battle_won)
	EventBus.battle_lost.connect(_on_battle_lost)


# ─── 公共方法 ────────────────────────────────────────────────

## 初始化并绑定棋子管理器。
## unit_manager: UnitManager 节点引用
func setup(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager


## 开始战斗（进入第 1 回合玩家阶段）。
## 由外部（BattleScene）在场景准备完毕后调用。
func start_battle() -> void:
	turn_number   = 1
	current_state = TurnState.PLAYER_TURN

	# 重置所有玩家棋子的行动点
	if _unit_manager != null:
		_reset_units_actions(_unit_manager.get_player_units())

	# 发出回合变化信号和玩家回合开始信号
	EventBus.turn_changed.emit(TurnState.PLAYER_TURN, turn_number)
	EventBus.player_turn_started.emit(turn_number)


## 玩家结束回合（切换到敌方回合）。
## 防止重复调用：若当前不是玩家回合则直接返回。
func end_player_turn() -> void:
	if current_state != TurnState.PLAYER_TURN:
		return

	current_state = TurnState.ENEMY_TURN

	# 重置所有敌方棋子的行动点
	if _unit_manager != null:
		_reset_units_actions(_unit_manager.get_enemy_units())

	# 发出回合变化信号和敌方回合开始信号
	EventBus.turn_changed.emit(TurnState.ENEMY_TURN, turn_number)
	EventBus.enemy_turn_started.emit(turn_number)


## 敌方结束回合（由 AIController 调用，切换到下一个玩家回合）。
## 防止重复调用：若当前不是敌方回合则直接返回。
func end_enemy_turn() -> void:
	if current_state != TurnState.ENEMY_TURN:
		return

	turn_number  += 1
	current_state = TurnState.PLAYER_TURN

	# 重置所有玩家棋子的行动点
	if _unit_manager != null:
		_reset_units_actions(_unit_manager.get_player_units())

	# 发出回合变化信号和玩家回合开始信号
	EventBus.turn_changed.emit(TurnState.PLAYER_TURN, turn_number)
	EventBus.player_turn_started.emit(turn_number)


## 结束游戏。
## player_won: true = 玩家胜利，false = 玩家失败
func end_game(player_won: bool) -> void:
	# 防止无限循环：若已处于 GAME_OVER 状态则直接返回
	if current_state == TurnState.GAME_OVER:
		return

	current_state = TurnState.GAME_OVER

	# 发出回合变化信号（通知 UI 更新）
	EventBus.turn_changed.emit(TurnState.GAME_OVER, turn_number)

	# 根据胜负发出对应信号
	if player_won:
		EventBus.battle_won.emit()
	else:
		EventBus.battle_lost.emit()


# ─── 私有辅助方法 ────────────────────────────────────────────

## 重置指定棋子列表中所有棋子的行动点。
## units: 需要重置行动点的棋子数组
func _reset_units_actions(units: Array[Unit]) -> void:
	for unit in units:
		unit.reset_actions()


# ─── 信号处理 ────────────────────────────────────────────────

## 响应 battle_won 信号：触发游戏结束（玩家胜利）。
func _on_battle_won() -> void:
	end_game(true)


## 响应 battle_lost 信号：触发游戏结束（玩家失败）。
func _on_battle_lost() -> void:
	end_game(false)
