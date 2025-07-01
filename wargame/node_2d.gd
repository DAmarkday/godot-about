# ===============================
# 简化版完整Game.gd - 包含UI创建
# ===============================

# ===============================
# 主游戏逻辑 - 这是真正的入口点
# ===============================
extends Node2D

var battle_system: BattleSystem
var battle_ui: BattleUI

func _ready():
	print("游戏启动...")
	_create_ui()
	_create_battle_system()
	_start_test_battle()

func _create_ui():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	battle_ui = BattleUI.new()
	canvas_layer.add_child(battle_ui)

func _create_battle_system():
	battle_system = BattleSystem.new()
	add_child(battle_system)
	battle_ui.initialize(battle_system)

func _start_test_battle():
	var player1 = _create_unit("战士", 120, 25, 8, 12, Color.BLUE)
	var player2 = _create_unit("法师", 80, 35, 3, 15, Color.CYAN)
	var enemy1 = _create_unit("骷髅兵", 60, 18, 5, 10, Color.RED)
	var enemy2 = _create_unit("兽人", 100, 22, 7, 8, Color.DARK_RED)
	
	battle_system.start_battle([player1, player2], [enemy1, enemy2])

func _create_unit(name: String, hp: int, atk: int, def: int, spd: int, color: Color) -> BattleUnit:
	var unit = BattleUnit.new()
	unit.unit_name = name
	unit.max_health = hp
	unit.attack_power = atk
	unit.defense = def
	unit.speed = spd
	
	# 创建视觉表示
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	unit.add_child(sprite)
	
	var label = Label.new()
	label.text = name
	label.position = Vector2(-16, -45)
	label.add_theme_font_size_override("font_size", 12)
	unit.add_child(label)
	
	add_child(unit)
	return unit

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
