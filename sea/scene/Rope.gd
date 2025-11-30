# Rope.gd  —— 终极修复版（拉力方向正确！鱼拉船方向一致）
extends Node2D

@export var segment_length: float = 9.0
@export var gravity: float = 600.0
@export var damping: float = 0.98
@export var stiffness: float = 1.0
@export var iterations: int = 35

# 拉力控制（已优化）
@export var max_tension_force: float = 1200.0    # 最大总拉力（适中）
@export var tension_ramp_up_time: float = 0.2    # 更快渐增
@export var min_stretch_for_force: float = 0.3   # 更敏感

var points: Array[Vector2] = []
var old_points: Array[Vector2] = []
var pinned: Array[bool] = []

var ship_anchor: Marker2D = null
var fish: Node2D = null

var time_attached: float = 0.0

@onready var line: Line2D = $Line2D

func _ready() -> void:
	line.width = 6
	line.default_color = Color8(139, 69, 19)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	visible = false

# 发射绳子（不变）
func connect_to(ship_marker: Marker2D, target_fish: Node2D) -> void:
	ship_anchor = ship_marker
	fish = target_fish
	time_attached = 0.0
	visible = true
	
	var start := ship_marker.global_position
	var end := target_fish.global_position
	var dist := start.distance_to(end)
	var seg_count = max(10, int(dist / segment_length) + 1)
	
	points.clear()
	old_points.clear()
	pinned.clear()
	
	for i in seg_count + 1:
		var t = float(i) / seg_count
		var pos := start.lerp(end, t)
		points.append(pos)
		old_points.append(pos)
		pinned.append(i == 0 || i == seg_count)
	
	# 首帧拉直
	for _i in 150:
		_satisfy_constraints()
	
	line.points = points.duplicate()

func _physics_process(delta: float) -> void:
	if points.size() < 2:
		return
	
	time_attached += delta
	
	# Verlet积分
	for i in points.size():
		if pinned[i]: continue
		var vel := points[i] - old_points[i]
		old_points[i] = points[i]
		points[i] += vel * damping + Vector2(0, gravity) * delta * delta
	
	# 约束
	for _it in iterations:
		_satisfy_constraints()
	
	# 锚点强制
	if ship_anchor and points.size() > 0:
		points[0] = ship_anchor.global_position
		old_points[0] = points[0]
	if fish and points.size() > 0:
		points[points.size() - 1] = fish.global_position
		old_points[points.size() - 1] = points[points.size() - 1]
	
	# 【修复版】施加正确拉力
	_apply_tension(delta)
	
	line.points = points.duplicate()

func _satisfy_constraints() -> void:
	for i in points.size() - 1:
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[i + 1]
		var delta_vec := p2 - p1
		var current_dist := delta_vec.length()
		if current_dist < 0.001: continue
		
		var difference := segment_length - current_dist
		var correction := delta_vec * (difference / current_dist) * 0.5 * stiffness
		
		if not pinned[i]:
			points[i] -= correction
		if not pinned[i + 1]:
			points[i + 1] += correction

# 【核心修复】_apply_tension —— 拉力方向正确！
func _apply_tension(delta: float) -> void:
	if not ship_anchor: return
	var ship := ship_anchor.get_parent() as CharacterBody2D
	if not ship: return
	
	var total_force := Vector2.ZERO
	
	# 【关键修复】dir = 从船端指向鱼端（points[i]→points[i+1]）
	for i in points.size() - 1:
		# CORRECT DIR: 从当前段船侧 → 鱼侧（拉船向鱼）
		var dir := (points[i + 1] - points[i]).normalized()
		var stretch := points[i].distance_to(points[i + 1]) - segment_length
		if stretch > min_stretch_for_force:
			total_force += dir * stretch * 200.0  # 适中系数
	
	# 拉力限制 & 渐增
	total_force = total_force.limit_length(max_tension_force)
	var ramp = min(1.0, time_attached / tension_ramp_up_time)
	total_force *= ramp
	
	# 应用到船（现在方向完美一致！）
	ship.velocity += total_force * delta
