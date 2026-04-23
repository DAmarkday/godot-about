## BattleScene.gd
## 主战斗场景控制器，负责初始化所有系统、生成地图、放置棋子并处理玩家输入。
## 继承 Node2D，作为游戏的根场景节点。
class_name BattleScene extends Node2D

# ─── 常量 ────────────────────────────────────────────────────

## 格子大小（像素）
const CELL_SIZE: int = 64

## 地图宽度（格子数）
const MAP_WIDTH: int = 10

## 地图高度（格子数）
const MAP_HEIGHT: int = 10

# ─── 系统节点引用 ────────────────────────────────────────────

## 棋子管理器
@onready var unit_manager: UnitManager = $Systems/UnitManager

## 回合管理器
@onready var turn_manager: TurnManager = $Systems/TurnManager

## 移动系统
@onready var movement_system: MovementSystem = $Systems/MovementSystem

## 战斗系统
@onready var combat_system: CombatSystem = $Systems/CombatSystem

## AI 控制器
@onready var ai_controller: AIController = $Systems/AIController

## 棋子行动状态视觉反馈管理器
@onready var unit_state_visual: UnitStateVisual = $UILayer/UnitStateVisual

## 结束回合按钮
@onready var end_turn_button: EndTurnButton = $UILayer/EndTurnButton

## 高亮层（显示移动/攻击范围）
@onready var highlight_layer: HighlightLayer = $BattleMap/HighlightLayer

## 棋子容器节点
@onready var units_container: Node2D = $BattleMap/UnitsContainer

## 地图加载器
@onready var map_loader: MapLoader = $BattleMap/MapLoader

# ─── 运行时状态 ──────────────────────────────────────────────

## 当前地图数据
var map_data: MapData = null

## 当前选中的棋子
var selected_unit: Unit = null

## 当前可移动格子列表
var reachable_cells: Array[Vector2i] = []

## 当前可攻击格子列表
var attack_cells: Array[Vector2i] = []


# ─── 生命周期 ────────────────────────────────────────────────

func _ready() -> void:
	# 1. 初始化 TurnManager（绑定 UnitManager）
	turn_manager.setup(unit_manager)

	# 2. 生成地图（随机种子）
	map_data = MapGenerator.generate_battle_map(MAP_WIDTH, MAP_HEIGHT, randi())

	# 3. 渲染地图（调用 map_loader.load_map）
	map_loader.load_map(map_data)

	# 4. 放置初始棋子
	_spawn_initial_units()

	# 5. 初始化棋子状态视觉反馈（注入 UnitManager）
	unit_state_visual.setup(unit_manager)

	# 6. 连接结束回合按钮信号到 TurnManager
	end_turn_button.end_turn_requested.connect(turn_manager.end_player_turn)

	# 7. 开始战斗
	turn_manager.start_battle()

	# 8. 监听敌方回合开始信号
	EventBus.enemy_turn_started.connect(_on_enemy_turn_started)


# ─── 输入处理 ────────────────────────────────────────────────

## 处理玩家输入
func _input(event: InputEvent) -> void:
	# 非玩家回合时忽略所有输入
	if turn_manager.current_state != TurnManager.TurnState.PLAYER_TURN:
		return

	# 只处理鼠标左键点击
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# 将鼠标坐标转换为格子坐标
	var cell = _world_to_cell(get_global_mouse_position())
	_handle_cell_click(cell)


# ─── 点击逻辑 ────────────────────────────────────────────────

## 处理格子点击逻辑
func _handle_cell_click(cell: Vector2i) -> void:
	var clicked_unit = unit_manager.get_unit_at(cell)

	if selected_unit == null:
		# 未选中状态：点击己方棋子则选中
		if clicked_unit != null and clicked_unit.team == 0:
			_select_unit(clicked_unit)
	else:
		# 已选中状态
		if cell in reachable_cells:
			# 点击可移动格子：执行移动
			movement_system.try_move(selected_unit, cell, map_data, unit_manager)
			# 移动后更新高亮（保留攻击范围）
			reachable_cells = []
			attack_cells = combat_system.calculate_attack_cells(selected_unit)
			highlight_layer.clear_highlights()
			highlight_layer.show_attack_range(attack_cells)
		elif clicked_unit != null and clicked_unit.team == 1 and cell in attack_cells:
			# 点击攻击范围内的敌方棋子：执行攻击
			combat_system.try_attack(selected_unit, cell, unit_manager)
			_deselect_unit()
		elif clicked_unit != null and clicked_unit.team == 0:
			# 点击另一个己方棋子：切换选中
			_deselect_unit()
			_select_unit(clicked_unit)
		else:
			# 点击空白处：取消选中
			_deselect_unit()


# ─── 选中/取消选中 ───────────────────────────────────────────

## 选中棋子，显示移动和攻击范围高亮
func _select_unit(unit: Unit) -> void:
	selected_unit = unit
	reachable_cells = movement_system.calculate_reachable_cells(unit, map_data, unit_manager)
	attack_cells = combat_system.calculate_attack_cells(unit)
	highlight_layer.clear_highlights()
	highlight_layer.show_movement_range(reachable_cells)
	highlight_layer.show_attack_range(attack_cells)
	EventBus.unit_selected.emit(unit)


## 取消选中棋子，清除所有高亮
func _deselect_unit() -> void:
	if selected_unit != null:
		EventBus.unit_deselected.emit(selected_unit)
	selected_unit = null
	reachable_cells = []
	attack_cells = []
	highlight_layer.clear_highlights()


# ─── 坐标转换 ────────────────────────────────────────────────

## 世界坐标转格子坐标
func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / CELL_SIZE, int(world_pos.y) / CELL_SIZE)


## 格子坐标转世界坐标（格子中心）
func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2.0, cell.y * CELL_SIZE + CELL_SIZE / 2.0)


# ─── 棋子生成 ────────────────────────────────────────────────

## 放置初始棋子
func _spawn_initial_units() -> void:
	# 玩家棋子：战士在 (1,8)，弓手在 (2,8)
	_spawn_unit(preload("res://resource/units/warrior.tres"), Vector2i(1, 8))
	_spawn_unit(preload("res://resource/units/archer.tres"), Vector2i(2, 8))
	# 敌方棋子：哥布林在 (7,1)，巨魔在 (8,1)
	_spawn_unit(preload("res://resource/units/goblin.tres"), Vector2i(7, 1))
	_spawn_unit(preload("res://resource/units/troll.tres"), Vector2i(8, 1))


## 生成单个棋子并注册到管理器
func _spawn_unit(data: UnitData, cell: Vector2i) -> void:
	var unit_scene = preload("res://scene/units/unit_template.tscn")
	var unit: Unit = unit_scene.instantiate()
	unit.setup(data)
	unit.grid_position = cell
	unit.position = _cell_to_world(cell)
	units_container.add_child(unit)
	unit_manager.register_unit(unit)


# ─── 信号处理 ────────────────────────────────────────────────

## 响应敌方回合开始信号，触发 AI 执行敌方回合
func _on_enemy_turn_started(_turn_number: int) -> void:
	_deselect_unit()
	var enemy_units = unit_manager.get_enemy_units()
	var player_units = unit_manager.get_player_units()
	ai_controller.execute_enemy_turn(
		enemy_units, player_units, map_data,
		movement_system, combat_system, unit_manager, turn_manager
	)
