# ===============================
# BattleUI 类定义 - 纯代码版本
# ===============================
class_name BattleUI
extends Control

signal action_requested(action: BattleAction)

# UI 组件引用（程序化创建）
var current_turn_label: Label
var round_label: Label
var unit_name_label: Label
var health_bar: ProgressBar
var stats_label: Label
var attack_button: Button
var move_button: Button
var defend_button: Button
var wait_button: Button

var battle_system: BattleSystem
var current_unit: BattleUnit

func _ready():
	_create_ui_elements()
	_connect_buttons()
	_disable_action_buttons()

func _create_ui_elements():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)
	
	# 回合信息
	var turn_info = VBoxContainer.new()
	main_container.add_child(turn_info)
	
	current_turn_label = Label.new()
	current_turn_label.text = "等待战斗开始..."
	current_turn_label.add_theme_font_size_override("font_size", 20)
	turn_info.add_child(current_turn_label)
	
	round_label = Label.new()
	round_label.text = "第 1 回合"
	turn_info.add_child(round_label)
	
	# 操作按钮
	var action_buttons = HBoxContainer.new()
	action_buttons.add_theme_constant_override("separation", 10)
	main_container.add_child(action_buttons)
	
	attack_button = Button.new()
	attack_button.text = "攻击"
	attack_button.custom_minimum_size = Vector2(80, 40)
	action_buttons.add_child(attack_button)
	
	move_button = Button.new()
	move_button.text = "移动"
	move_button.custom_minimum_size = Vector2(80, 40)
	action_buttons.add_child(move_button)
	
	defend_button = Button.new()
	defend_button.text = "防御"
	defend_button.custom_minimum_size = Vector2(80, 40)
	action_buttons.add_child(defend_button)
	
	wait_button = Button.new()
	wait_button.text = "等待"
	wait_button.custom_minimum_size = Vector2(80, 40)
	action_buttons.add_child(wait_button)
	
	# 单位信息
	var unit_info = VBoxContainer.new()
	main_container.add_child(unit_info)
	
	unit_name_label = Label.new()
	unit_name_label.text = "选择单位"
	unit_name_label.add_theme_font_size_override("font_size", 16)
	unit_info.add_child(unit_name_label)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(200, 20)
	health_bar.show_percentage = false
	unit_info.add_child(health_bar)
	
	stats_label = Label.new()
	stats_label.text = "属性信息"
	unit_info.add_child(stats_label)

func _connect_buttons():
	attack_button.pressed.connect(_on_attack_pressed)
	move_button.pressed.connect(_on_move_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	wait_button.pressed.connect(_on_wait_pressed)

func initialize(battle_sys: BattleSystem):
	battle_system = battle_sys
	battle_system.turn_manager.turn_started.connect(_on_turn_started)
	battle_system.turn_manager.round_started.connect(_on_round_started)
	battle_system.battle_ended.connect(_on_battle_ended)

func _on_turn_started(unit: BattleUnit):
	current_unit = unit
	_update_current_unit_display()
	
	if unit in battle_system.player_units:
		_enable_action_buttons()
	else:
		_disable_action_buttons()

func _on_round_started(round_number: int):
	round_label.text = "第 %d 回合" % round_number

func _on_battle_ended(winner: String):
	_disable_action_buttons()
	if winner == "Player":
		current_turn_label.text = "胜利！"
	else:
		current_turn_label.text = "失败..."

func _update_current_unit_display():
	if not current_unit:
		return
		
	current_turn_label.text = "当前行动: %s" % current_unit.unit_name
	unit_name_label.text = current_unit.unit_name
	health_bar.max_value = current_unit.max_health
	health_bar.value = current_unit.current_health
	stats_label.text = "攻击:%d 防御:%d 速度:%d" % [
		current_unit.attack_power,
		current_unit.defense, 
		current_unit.speed
	]

func _enable_action_buttons():
	attack_button.disabled = false
	move_button.disabled = false
	defend_button.disabled = false
	wait_button.disabled = false

func _disable_action_buttons():
	attack_button.disabled = true
	move_button.disabled = true
	defend_button.disabled = true
	wait_button.disabled = true

func _on_attack_pressed():
	var target = battle_system._find_nearest_enemy(current_unit, battle_system.enemy_units)
	if target:
		var action = BattleAction.new(BattleAction.ActionType.ATTACK, current_unit)
		action.target = target
		battle_system.execute_player_action(action)

func _on_move_pressed():
	print("移动功能暂未实现")
	var action = BattleAction.new(BattleAction.ActionType.WAIT, current_unit)
	battle_system.execute_player_action(action)

func _on_defend_pressed():
	var action = BattleAction.new(BattleAction.ActionType.DEFEND, current_unit)
	battle_system.execute_player_action(action)

func _on_wait_pressed():
	var action = BattleAction.new(BattleAction.ActionType.WAIT, current_unit)
	battle_system.execute_player_action(action)
