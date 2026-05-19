## BattleScene.gd
## 主战斗场景控制器，负责初始化所有系统、生成地图、放置棋子并处理玩家输入。
## 继承 Node2D，作为游戏的根场景节点。
class_name BattleScene extends Node2D

# ─── 常量 ────────────────────────────────────────────────────

## 格子大小（像素）
const CELL_SIZE: int = 64

## 地图宽度（格子数）
const MAP_WIDTH: int = 8

## 地图高度（格子数）
const MAP_HEIGHT: int = 8


# ─── 系统节点引用 ────────────────────────────────────────────

## 棋子管理器
@onready var unit_manager: UnitManager = $Systems/UnitManager
#
### 回合管理器
#@onready var turn_manager: TurnManager = $Systems/TurnManager
#
## 移动系统
@onready var movement_system: MovementSystem = $Systems/MovementSystem
#
### 战斗系统
#@onready var combat_system: CombatSystem = $Systems/CombatSystem
#
### AI 控制器
#@onready var ai_controller: AIController = $Systems/AIController
#
### 棋子行动状态视觉反馈管理器
@onready var unit_state_visual: UnitStateVisual = $UILayer/UnitStateVisual
#
### 结束回合按钮
#@onready var end_turn_button: EndTurnButton = $UILayer/EndTurnButton

@onready var camera_node:Camera2D = $Camera2D

@onready var battle_map = $BattleMap
# 地形层
@onready var terrain_layer =$BattleMap/TerrainLayer

# 高亮层（显示移动/攻击范围）
@onready var highlight_layer: HighlightLayer = $BattleMap/HighlightLayer

# 路线箭头指引层 
@onready var path_layer = $BattleMap/PathLayer
### 棋子容器节点
@onready var units_container: Node2D = $BattleMap/UnitsContainer
#
## 地图加载器
@onready var map_loader: MapLoader = $BattleMap/MapLoader as MapLoader

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
	#turn_manager.setup(unit_manager)

	# 2. 生成地图（随机种子）
	map_data = MapGenerator.generate_battle_map(MAP_WIDTH, MAP_HEIGHT, randi())
	print("map_data is ",map_data.to_json())
	

	# 3. 渲染地图（调用 map_loader.load_map）
	map_loader.load_map(map_data)

	# 4. 放置初始棋子
	_spawn_initial_units()
	
	battle_map.center_map_with_camera(terrain_layer,camera_node)

	# 5. 初始化棋子状态视觉反馈（注入 UnitManager）
	#unit_state_visual.setup(unit_manager)

	# 6. 连接结束回合按钮信号到 TurnManager
	#end_turn_button.end_turn_requested.connect(turn_manager.end_player_turn)

	# 7. 开始战斗
	#turn_manager.start_battle()

	# 8. 监听敌方回合开始信号
	#EventBus.enemy_turn_started.connect(_on_enemy_turn_started)
	
# ─── 棋子生成 ────────────────────────────────────────────────

## 放置初始棋子
func _spawn_initial_units() -> void:
	# 玩家棋子：战士在 (1,8)，弓手在 (2,8)
	_spawn_unit(preload("res://resource/units/player/data/warrior.tres"), Vector2i(1, 2))
	_spawn_unit(preload("res://resource/units/player/data/knight.tres"), Vector2i(2, 3))
	# 敌方棋子：哥布林在 (7,1)，巨魔在 (8,1)
	_spawn_unit(preload("res://resource/units/enemy/data/boomer.tres"), Vector2i(4, 5))
	_spawn_unit(preload("res://resource/units/enemy/data/firer.tres"), Vector2i(5, 2))
	#_spawn_unit(preload("res://resource/units/troll.tres"), Vector2i(8, 1))
	
## 生成单个棋子并注册到管理器
func _spawn_unit(data: UnitData, cell: Vector2i) -> void:
	var unit_scene = preload("res://scene/units/unit_template.tscn")
	var unit: Unit = unit_scene.instantiate()
	unit.setup(data)
	unit.grid_position = cell
	unit.global_position = GridUtils.cell_to_world(terrain_layer,cell)
	units_container.add_child(unit)
	unit_manager.register_unit(unit)
	
# ─── 坐标转换 ────────────────────────────────────────────────

## 世界坐标转格子坐标
#func _world_to_cell(world_pos: Vector2) -> Vector2i:
	#return Vector2i(int(world_pos.x) / CELL_SIZE, int(world_pos.y) / CELL_SIZE)
#
#
### 格子坐标转世界坐标（格子中心）
#func _cell_to_world(cell: Vector2i) -> Vector2:
	#return Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2.0, cell.y * CELL_SIZE + CELL_SIZE / 2.0)


# ─── 输入处理 ────────────────────────────────────────────────

## 处理玩家输入
func _input(event: InputEvent) -> void:
	# 只处理鼠标移动
	if event is InputEventMouseMotion:
		# 将鼠标坐标转换为格子坐标
		var cell = GridUtils.world_to_cell(terrain_layer,get_global_mouse_position())
		_handle_cell_hover(cell)
		return
		
	#只处理鼠标左键点击
	# TODO 在棋子移动时动画播放移动动画还没结束时再重新移动棋子时会导致移动动画不能成功播放
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		# 将鼠标坐标转换为格子坐标
		path_layer.clear()
		var cell = GridUtils.world_to_cell(terrain_layer,get_global_mouse_position())
		_handle_cell_click(cell)
		return
		
# ─── 移动逻辑 ────────────────────────────────────────────────
## 处理鼠标悬浮逻辑
func _handle_cell_hover(cell: Vector2i) -> void:
	var hover_unit = unit_manager.get_unit_at(cell)
	if selected_unit == null:
		path_layer.clear()
		return
	else:
		if hover_unit != null:
			# 当前格子存在棋子或障碍物等等
			path_layer.clear()
			return
		else:
			pass
			var path=movement_system.query_move_valid_path(selected_unit,cell, map_data, unit_manager)
			print("path is ",path)
			path_layer.draw_path_on_layer(path)
		
	pass



# ─── 点击逻辑 ────────────────────────────────────────────────



## 处理格子点击逻辑
func _handle_cell_click(cell: Vector2i) -> void:
	var clicked_unit = unit_manager.get_unit_at(cell)

	if selected_unit == null:
		# 未选中状态：点击己方棋子则选中
		if clicked_unit != null and clicked_unit.team == MapData.TeamType.PLAYER:
			_select_unit(clicked_unit)
	else:
		# 已选中状态
		if selected_unit == clicked_unit:
			return
		if clicked_unit != null and clicked_unit.team == MapData.TeamType.PLAYER:
			selected_unit.clear_outline_hight_light()
			_select_unit(clicked_unit)
			return
		
		if cell in reachable_cells:
			# 点击可移动格子：执行移动
			movement_system.try_move(selected_unit, cell, map_data, unit_manager,terrain_layer)
			## 移动后更新高亮（保留攻击范围）
			reachable_cells = []
			#attack_cells = combat_system.calculate_attack_cells(selected_unit)
			_deselect_unit()
			#highlight_layer.show_attack_range(attack_cells)
		#elif clicked_unit != null and clicked_unit.team == 1 and cell in attack_cells:
			## 点击攻击范围内的敌方棋子：执行攻击
			#combat_system.try_attack(selected_unit, cell, unit_manager)
			#_deselect_unit()
		#elif clicked_unit != null and clicked_unit.team == 0:
			## 点击另一个己方棋子：切换选中
			#_deselect_unit()
			#_select_unit(clicked_unit)
		#else:
			## 点击空白处：取消选中
			#_deselect_unit()
			
# ─── 选中/取消选中 ───────────────────────────────────────────

## 选中棋子，显示移动和攻击范围高亮
func _select_unit(unit: Unit) -> void:
	selected_unit = unit
	unit.set_outline_hight_light()
	
	reachable_cells = movement_system.calculate_reachable_cells(unit, map_data, unit_manager)
	#attack_cells = combat_system.calculate_attack_cells(unit)
	highlight_layer.clear_highlights()
	highlight_layer.show_move_range(reachable_cells)
	#highlight_layer.show_attack_range(attack_cells)
	EventBus.unit_selected.emit(unit)
	
## 取消选中棋子，清除所有高亮
func _deselect_unit() -> void:
	if selected_unit != null:
		selected_unit.clear_outline_hight_light()
		EventBus.unit_deselected.emit(selected_unit)
	selected_unit = null
	reachable_cells = []
	#attack_cells = []
	highlight_layer.clear_highlights()
	
	
	
