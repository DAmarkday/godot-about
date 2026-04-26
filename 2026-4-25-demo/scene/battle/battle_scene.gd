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
#@onready var unit_manager: UnitManager = $Systems/UnitManager
#
### 回合管理器
#@onready var turn_manager: TurnManager = $Systems/TurnManager
#
### 移动系统
#@onready var movement_system: MovementSystem = $Systems/MovementSystem
#
### 战斗系统
#@onready var combat_system: CombatSystem = $Systems/CombatSystem
#
### AI 控制器
#@onready var ai_controller: AIController = $Systems/AIController
#
### 棋子行动状态视觉反馈管理器
#@onready var unit_state_visual: UnitStateVisual = $UILayer/UnitStateVisual
#
### 结束回合按钮
#@onready var end_turn_button: EndTurnButton = $UILayer/EndTurnButton
#
### 高亮层（显示移动/攻击范围）
#@onready var highlight_layer: HighlightLayer = $BattleMap/HighlightLayer
#
### 棋子容器节点
#@onready var units_container: Node2D = $BattleMap/UnitsContainer
#
## 地图加载器
@onready var map_loader: MapLoader = $BattleMap/MapLoader as MapLoader

# ─── 运行时状态 ──────────────────────────────────────────────

## 当前地图数据
var map_data: MapData = null

## 当前选中的棋子
#var selected_unit: Unit = null

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
	#_spawn_initial_units()

	# 5. 初始化棋子状态视觉反馈（注入 UnitManager）
	#unit_state_visual.setup(unit_manager)

	# 6. 连接结束回合按钮信号到 TurnManager
	#end_turn_button.end_turn_requested.connect(turn_manager.end_player_turn)

	# 7. 开始战斗
	#turn_manager.start_battle()

	# 8. 监听敌方回合开始信号
	#EventBus.enemy_turn_started.connect(_on_enemy_turn_started)
