## UnitInfoPanel.gd
## 棋子信息面板，显示当前选中棋子的详细属性。
## 监听 unit_selected / unit_deselected / unit_damaged 信号自动更新。
class_name UnitInfoPanel extends PanelContainer

## 棋子名称标签
@onready var name_label: Label = $VBox/NameLabel
## 血量标签
@onready var hp_label: Label = $VBox/HpLabel
## 移动力标签
@onready var move_label: Label = $VBox/MoveLabel
## 攻击力标签
@onready var atk_label: Label = $VBox/AtkLabel
## 防御力标签
@onready var def_label: Label = $VBox/DefLabel

func _ready() -> void:
	# 监听棋子选中、取消选中、受伤信号
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.unit_deselected.connect(_on_unit_deselected)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	# 初始隐藏面板
	hide()

## 响应棋子选中信号，显示棋子属性
## unit: 被选中的棋子节点
func _on_unit_selected(unit) -> void:
	name_label.text = unit.unit_name
	hp_label.text = "血量：%d / %d" % [unit.current_hp, unit.max_hp]
	move_label.text = "移动力：%d" % unit.movement
	atk_label.text = "攻击力：%d" % unit.attack_power
	def_label.text = "防御力：%d" % unit.defense
	show()

## 响应棋子取消选中信号，隐藏面板
## _unit: 取消选中的棋子节点（未使用）
func _on_unit_deselected(_unit) -> void:
	hide()

## 响应棋子受伤信号，更新血量显示
## unit:         受伤的棋子节点
## _damage:      本次伤害值（未使用）
## remaining_hp: 受伤后剩余血量
func _on_unit_damaged(unit, _damage, remaining_hp) -> void:
	# 如果受伤的是当前选中的棋子，更新血量显示
	hp_label.text = "血量：%d / %d" % [remaining_hp, unit.max_hp]
