extends Node2D
class_name BossSnake
enum State {
	IDLE,
	SEEKING,
	EATING
}

# 导出参数，方便编辑器调整
@export var speed: float = 100.0  # 蛇移动速度（降低到50.0，突出缓慢转弯）
@export var base_segment_distance: float = 9.0  # 身体段基础间距（增大到16.0，宽松弧线）
@export var eating_growth_factor: float = 0.5  # 增长比例（保持0.2）
@export var turn_smoothing: float = 0.3  # 转弯平滑因子（降低到0.3，渐进转向）
@export var path_smoothing: float = 0.5  # 路径曲线平滑因子（提高到0.5，圆润弧线）

# 预加载场景
@onready var head_scene = preload("res://scene/enemy/snake/Head.tscn")  # 蛇头场景
@onready var body_scene = preload("res://scene/enemy/snake/Body.tscn")  # 蛇身场景
@onready var tail_scene = preload("res://scene/enemy/snake/Tail.tscn")  # 蛇尾场景
@onready var food_scene = preload("res://scene/enemy/snake/Food.tscn")  # 食物场景
@onready var BossNode = $Boss
# 在类顶部添加节点池变量
#var visual_nodes: Array[Node2D] = []  # 存储当前使用的视觉节点


# 游戏状态变量
var _snakeBodyPosition: Array[Vector2] = []  # 存储蛇身体段位置
var direction: Vector2 = Vector2.RIGHT  # 当前移动方向
var food: Node2D = null  # 当前食物实例
var _currentState: State = State.IDLE  # 当前状态
var screen_width: float = 0  # 屏幕宽度
var screen_height: float = 0  # 屏幕高度
var _pathPoints: Array[Vector2] = []  # 路径点，仅存储位置

func _ready() -> void:
	# 初始化游戏
	Game.map = self
	_initSnake()
	_createFood()
	_changeStatus(State.SEEKING)
	
	#初始化蛇()
	#生成食物()
	#更新视觉效果()
	#进入状态(State.SEEKING)

# 每帧处理
func _process(delta: float) -> void:
	match _currentState:
		State.IDLE:
			#处理空闲状态(delta)
			_handleIdle(delta)
		State.SEEKING:
			_handleSeeking(delta)
		State.EATING:
			_handleEating(delta)

# 空闲状态逻辑
func _handleIdle(_delta: float) -> void:
	pass
	
# 寻食状态：蛇追逐食物
func _handleSeeking(delta: float) -> void:
	var head = _snakeBodyPosition[0]
	var target_direction = (food.position - head).normalized()  # 目标方向
	
	# 非常平滑的转向，生成宽松圆弧
	direction = direction.lerp(target_direction, turn_smoothing * delta * 10.0).normalized()
	# 移动蛇头
	var velocity = direction * speed * delta
	var new_head = head + velocity
	
	# 记录路径点，增加密度
	_pathPoints.insert(0, new_head)
	_snakeBodyPosition[0] = new_head
	
	var segment_distance = 获取动态间距()
	
	# 更新身体段位置，沿着平滑曲线
	for i in range(1, _snakeBodyPosition.size()):
		var target = 获取平滑路径点位置(i * segment_distance)
		_snakeBodyPosition[i] = target  # 直接设置，确保间距
	
	# 清理多余路径点
	清理路径点(_snakeBodyPosition.size() * segment_distance)
	
	# 检查是否吃到食物
	if new_head.distance_to(food.position) < segment_distance:
		_changeStatus(State.EATING)	

	_updateBoss()
	pass

func _updateBoss():
	var base_scale = 1.0 + max(0, _snakeBodyPosition.size() - 4) * eating_growth_factor
	var snakeBodyNodeArr = BossNode.get_children()

	# 确保节点数量与身体段一致
	if snakeBodyNodeArr.size() != _snakeBodyPosition.size():
		print("警告：节点数量与身体段不匹配，节点: ", snakeBodyNodeArr.size(), ", 身体: ", _snakeBodyPosition.size())
		return

	for index in range(snakeBodyNodeArr.size()):
		var scale = base_scale
		var rotation = direction.angle()

		# 计算当前段的方向
		if index > 0:
			var segment_dir = (_snakeBodyPosition[index-1] - _snakeBodyPosition[index]).normalized()
			var target_rotation = segment_dir.angle()
			
			# 尾巴特殊处理
			if index == _snakeBodyPosition.size() - 1 and _snakeBodyPosition.size() > 1:
				# 尾巴仅基于最后两段方向，增加延迟效果
				rotation = target_rotation  # 直接使用最后段方向
				if _snakeBodyPosition.size() > 2:
					# 可选：轻微插值前段方向，保持平滑
					var prev_dir = (_snakeBodyPosition[index-1] - _snakeBodyPosition[index]).normalized()
					rotation = lerp_angle(prev_dir.angle(), target_rotation, 0.5)  # 降低插值因子
			else:
				# 其他段平滑插值
				rotation = lerp_angle(rotation, target_rotation, 0.7)

		# 更新节点属性
		snakeBodyNodeArr[index].position = _snakeBodyPosition[index]
		snakeBodyNodeArr[index].rotation = rotation
		snakeBodyNodeArr[index].scale = Vector2(scale, scale)
		if index == _snakeBodyPosition.size() - 1:
			snakeBodyNodeArr[index].scale *= 1.15  # 尾部稍大
		snakeBodyNodeArr[index].add_to_group("snake_body")
	

func _handleEating(delta: float) -> void:
	var segment_distance = 获取动态间距()
	var last_segment = _snakeBodyPosition[-1]
	var second_last = _snakeBodyPosition[-2] if _snakeBodyPosition.size() >= 2 else last_segment
	var tail_direction = (last_segment - second_last).normalized()
	var new_segment = last_segment - tail_direction * segment_distance
	_snakeBodyPosition.append(new_segment)
	_pathPoints.append(new_segment)
	
	var snakeBodyNodeArr = BossNode.get_children()
	
	var new_node = body_scene.instantiate()
	BossNode.add_child(new_node)
	
	BossNode.move_child(new_node,snakeBodyNodeArr.size()-1)
	
	_createFood()
	_changeStatus(State.SEEKING)
	pass

# 获取平滑路径点位置，使用Catmull-Rom样条
func 获取平滑路径点位置(distance: float) -> Vector2:
	var accumulated_distance: float = 0.0
	for i in range(_pathPoints.size() - 1):
		var p1 = _pathPoints[i]
		var p2 = _pathPoints[i + 1]
		var segment_length = p1.distance_to(p2)
		
		if accumulated_distance + segment_length >= distance:
			var remaining = distance - accumulated_distance
			var t = clamp(remaining / segment_length, 0.0, 1.0)
			
			# 使用Catmull-Rom样条插值
			if i >= 1 and i < _pathPoints.size() - 2:
				var p0 = _pathPoints[i-1]
				var p3 = _pathPoints[i+2]
				return _catmull_rom_interpolate(p0, p1, p2, p3, t)
			else:
				return p1.lerp(p2, t)
		
		accumulated_distance += segment_length
	
	# 如果距离超出，返回最后一个点
	return _pathPoints[-1] if _pathPoints.size() > 0 else _snakeBodyPosition[0]
	
# 计算动态间距
func 获取动态间距() -> float:
	var growth_scale = 1.0 + max(0, _snakeBodyPosition.size() - 4) * eating_growth_factor
	return base_segment_distance * growth_scale

# 清理多余路径点
func 清理路径点(max_distance: float) -> void:
	var accumulated_distance: float = 0.0
	var keep_points = _pathPoints.size()
	for i in range(_pathPoints.size() - 1):
		var p1 = _pathPoints[i]
		var p2 = _pathPoints[i + 1]
		accumulated_distance += p1.distance_to(p2)
		if accumulated_distance > max_distance + base_segment_distance * 5:  # 增加缓冲
			keep_points = i + 5  # 多保留点支持宽松弧线
			break
	if keep_points < _pathPoints.size():
		_pathPoints.resize(keep_points)

	
# Catmull-Rom样条插值，调整张力以形成宽松弧线
func _catmull_rom_interpolate(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 = t * t
	var t3 = t2 * t
	# Catmull-Rom公式，调整张力（path_smoothing）使弧线更宽松
	var tension = 1.0 - path_smoothing  # 降低张力，弧线更圆润
	var a = (-tension * p0 + 2.0 * tension * p1 - tension * p2) / 2.0
	var b = (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) / 2.0
	var c = (-p0 + p2) / 2.0
	var d = p1
	return a * t3 + b * t2 + c * t + d
	
func _initSnake():
	_snakeBodyPosition.clear()
	_pathPoints.clear()
	# 蛇的生成位置
	var start_pos = Vector2(screen_width / 2, screen_height / 2)
	_snakeBodyPosition.append(start_pos)
	
	for i in range(3):
		var pos = start_pos - Vector2(base_segment_distance * (i + 1), 0)
		_snakeBodyPosition.append(pos)
		_pathPoints.append(pos)
	_pathPoints.append(start_pos)
	
	var hs=head_scene.instantiate()
	var ts=tail_scene.instantiate()
	
	for i in range(_snakeBodyPosition.size()):
		var new_node = null
		if i == 0:
			hs.position = _snakeBodyPosition[i]
			new_node = hs
		if 0<i&&i<_snakeBodyPosition.size()-1:
			var bs=body_scene.instantiate()
			bs.position = _snakeBodyPosition[i]
			new_node = bs
		if i == _snakeBodyPosition.size()-1:
			ts.position = _snakeBodyPosition[i]
			new_node = ts
		BossNode.add_child(new_node)
	pass


func _createFood():
	if food:
		food.queue_free()
	
	food = food_scene.instantiate()
	var margin = base_segment_distance * 2  # 避免食物贴边
	food.position = Vector2(
		randf_range(margin, screen_width - margin),
		randf_range(margin, screen_height - margin)
	)
	add_child(food)
	
# 切换状态
func _changeStatus(new_state: State) -> void:
	_currentState = new_state
	print("进入状态：", State.keys()[new_state])


# 设置屏幕范围
func setCurActiveRange(w: int, h: int) -> void:
	screen_width = w
	screen_height = h
