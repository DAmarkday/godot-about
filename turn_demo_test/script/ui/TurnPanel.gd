## TurnPanel.gd
## 回合信息面板，显示当前回合数和行动方。
## 监听 EventBus.turn_changed 信号自动更新文本。
class_name TurnPanel extends Label

func _ready() -> void:
	# 监听回合变化信号
	EventBus.turn_changed.connect(_on_turn_changed)
	text = "第 1 回合 - 玩家回合"

## 响应回合变化信号，更新显示文本
## new_state:   新的回合状态（0=玩家回合，1=敌方回合，2=游戏结束）
## turn_number: 当前回合数
func _on_turn_changed(new_state: int, turn_number: int) -> void:
	match new_state:
		0: text = "第 %d 回合 - 玩家回合" % turn_number   # PLAYER_TURN
		1: text = "第 %d 回合 - 敌方回合" % turn_number   # ENEMY_TURN
		2: text = "游戏结束"                               # GAME_OVER
