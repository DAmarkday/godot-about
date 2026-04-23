## GameResultPanel.gd
## 游戏结果界面，在战斗结束时显示胜利或失败提示。
## 监听 battle_won / battle_lost 信号自动显示。
class_name GameResultPanel extends PanelContainer

## 结果标题标签（胜利/失败）
@onready var result_label: Label = $VBox/ResultLabel
## 提示信息标签
@onready var hint_label: Label = $VBox/HintLabel

func _ready() -> void:
	# 监听胜负信号
	EventBus.battle_won.connect(_on_battle_won)
	EventBus.battle_lost.connect(_on_battle_lost)
	# 初始隐藏面板
	hide()

## 响应胜利信号，显示胜利界面
func _on_battle_won() -> void:
	result_label.text = "🎉 胜利！"
	hint_label.text = "所有敌方棋子已被消灭"
	show()

## 响应失败信号，显示失败界面
func _on_battle_lost() -> void:
	result_label.text = "💀 失败！"
	hint_label.text = "所有己方棋子已阵亡"
	show()
