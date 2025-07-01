# ===============================
# 使用示例 - Game.gd
# ===============================
extends Node

var battle_system: BattleSystem

func _ready():
	# 创建战斗系统
	battle_system = BattleSystem.new()
	add_child(battle_system)
	
	# 创建测试单位
	var player1 = BattleUnit.new()
	player1.unit_name = "战士"
	player1.max_health = 120
	player1.attack_power = 25
	player1.defense = 8
	player1.speed = 12
	
	var player2 = BattleUnit.new()
	player2.unit_name = "法师"
	player2.max_health = 80
	player2.attack_power = 35
	player2.defense = 3
	player2.speed = 15
	
	var enemy1 = BattleUnit.new()
	enemy1.unit_name = "骷髅兵"
	enemy1.max_health = 60
	enemy1.attack_power = 18
	enemy1.defense = 5
	enemy1.speed = 10
	
	var enemy2 = BattleUnit.new()
	enemy2.unit_name = "兽人"
	enemy2.max_health = 100
	enemy2.attack_power = 22
	enemy2.defense = 7
	enemy2.speed = 8
	
	# 开始战斗
	battle_system.start_battle([player1, player2], [enemy1, enemy2])

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# 示例：让当前单位攻击最近的敌人
		var current_unit = battle_system.turn_manager.get_current_unit()
		if current_unit and current_unit in battle_system.player_units:
			_try_attack_nearest_enemy(current_unit)

func _try_attack_nearest_enemy(unit: BattleUnit):
	var nearest_enemy = battle_system._find_nearest_enemy(unit, battle_system.enemy_units)
	if nearest_enemy:
		var action = BattleAction.new(BattleAction.ActionType.ATTACK, unit)
		action.target = nearest_enemy
		battle_system.execute_player_action(action)
