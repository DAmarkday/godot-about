## EndTurnButton.gd
## "结束回合"按钮，仅在玩家回合时可点击。
## 点击后发出 end_turn_requested 信号，由 BattleScene 连接到 TurnManager。
class_name EndTurnButton extends Button

## 玩家请求结束回合的信号（由 BattleScene 监听并转发给 TurnManager）
signal end_turn_requested()

func _ready() -> void:
	text = "结束回合"
	# 监听回合变化信号，控制按钮可用状态
	EventBus.turn_changed.connect(_on_turn_changed)
	# 监听按钮点击事件
	pressed.connect(_on_pressed)

## 响应回合变化信号，控制按钮启用/禁用
## new_state:    新的回合状态（0=玩家回合时启用，其他时禁用）
## _turn_number: 当前回合数（未使用）
func _on_turn_changed(new_state: int, _turn_number: int) -> void:
	# 只在玩家回合（state=0）时可点击
	disabled = (new_state != 0)

## 响应按钮点击，发出结束回合请求信号
func _on_pressed() -> void:
	end_turn_requested.emit()
