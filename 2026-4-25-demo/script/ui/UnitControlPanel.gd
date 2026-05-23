class_name UnitControlPanel extends PanelContainer
## UnitControlPanel.gd
## 棋子控制面板，显示当前选中棋子的详细属性。
## 监听 unit_selected / unit_deselected / unit_damaged 信号自动更新。

@onready var panel_show_node: MarginContainer =$MarginContainer

## 棋子名称标签
#@onready var name_label: Label =$PanelShow/MarginContainer/VBox/NameLabel
### 描述标签
#@onready var desc_label: Label = $PanelShow/MarginContainer/VBox/DescLabel
### 血量标签
#@onready var hp_label: Label = $PanelShow/MarginContainer/VBox/HpLabel
## 移动力标签
#@onready var move_label: Label = $MarginContainer/VBox/MoveLabel
## 攻击力标签
#@onready var atk_label: Label = $MarginContainer/VBox/AtkLabel
## 防御力标签
#@onready var def_label: Label = $MarginContainer/VBox/DefLabel

func _ready() -> void:
	# 监听棋子选中、取消选中、受伤信号
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.unit_deselected.connect(_on_unit_deselected)
	#EventBus.unit_damaged.connect(_on_unit_damaged)
	# 初始隐藏面板
	hide_panel()

## 响应棋子选中信号，显示棋子属性
## unit: 被选中的棋子节点
func _on_unit_selected(unit:Unit,isPlayerControl:bool) -> void:
	if isPlayerControl:
		show_panel()
	else:
		hide_panel()
	#name_label.text = "棋子: %s" % [unit.unit_name]
	#hp_label.text = "血量: %d / %d" % [unit.current_hp, unit.max_hp]
	#move_label.text = "移动力：%d" % unit.movement
	#atk_label.text = "攻击力：%d" % unit.attack_power
	#def_label.text = "防御力：%d" % unit.defense
## 响应棋子取消选中信号，隐藏面板
## _unit: 取消选中的棋子节点（未使用）
func _on_unit_deselected(_unit) -> void:
	hide_panel()

## 外部调用 用于控制面板显隐
func show_panel():
	panel_show_node.show()
	
	
	
func hide_panel():
	panel_show_node.hide()
	
