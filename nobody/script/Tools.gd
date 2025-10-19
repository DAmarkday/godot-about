extends Node
class_name Tools

static func get_random_unit_vector(random_range:Array=[-130, -150]) -> Vector2:
	# 生成 0 到 180 度的随机角度（转换为弧度）
	var angle_degrees = randf_range(random_range[0], random_range[1])
	var angle_radians = deg_to_rad(angle_degrees)
	
	# 使用 cos 和 sin 计算单位向量的 x 和 y 分量
	var unit_vector = Vector2(cos(angle_radians), sin(angle_radians))
	
	return unit_vector

# 计算抛物线轨迹的最高点和着陆点
# - init_pos: Vector2, 初始坐标
# - init_vel: Vector2, 初始速度
# - grav: float, 重力加速度
# - random_land_y_range: Array [min_offset, max_offset], 随机 y 偏移范围
# - 着陆点 y = 初始点 y + 随机值（从 random_land_y_range 抽取），且在抛物线上
# - 返回：{"apex": Vector2, "landing": Vector2}
# - 如果无有效着陆点，计算完整抛物线（y = init_pos.y）
static func calculate_trajectory_points(init_pos: Vector2, init_vel: Vector2, grav: float, random_land_y_range: Array) -> Dictionary:
	var gravity_vector = Vector2(0, grav)  # 重力仅在 y 方向
	
	# 调试输入参数
	print("init_pos: ", init_pos, ", init_vel: ", init_vel, ", grav: ", grav, ", random_land_y_range: ", random_land_y_range)
	
	# 计算最高点时间
	var t_apex: float = -init_vel.y / grav
	if t_apex < 0:
		t_apex = 0  # 初速向下，最高点为起始点
	
	# 最高点位置
	var apex_pos: Vector2 = init_pos + init_vel * t_apex + 0.5 * gravity_vector * t_apex * t_apex
	print("apex_pos: ", apex_pos, ", t_apex: ", t_apex)
	
	# 计算着陆点的 y 值
	var min_offset: float = random_land_y_range[0]
	var max_offset: float = random_land_y_range[1]
	var random_offset: float = randf_range(min_offset, max_offset)
	var y_landing: float = apex_pos.y + random_offset
	
	# 限制 y_landing 在抛物线可达范围内
	var max_y_drop: float = abs(apex_pos.y - init_pos.y) # 允许额外下降
	y_landing = clamp(y_landing, init_pos.y - max_y_drop, init_pos.y)
	print("random_offset: ", random_offset, ", y_landing: ", y_landing)
	
	# 抛物线方程求 t
	var a: float = 0.5 * grav
	var b: float = init_vel.y
	var c: float = init_pos.y - y_landing
	var discriminant: float = b * b - 4 * a * c
	print("discriminant: ", discriminant)
	
	var landing_pos: Vector2 = Vector2.INF
	if discriminant >= 0:
		var sqrt_disc: float = sqrt(discriminant)
		var t1: float = (-b + sqrt_disc) / (2 * a)
		var t2: float = (-b - sqrt_disc) / (2 * a)
		print("t1: ", t1, ", t2: ", t2)
		
		# 选择 t > t_apex（下行段），添加浮点误差容忍
		var valid_times: Array = []
		if t1 > t_apex + 0.0001:
			valid_times.append(t1)
		if t2 > t_apex + 0.0001:
			valid_times.append(t2)
		
		if not valid_times.is_empty():
			var t_land: float = valid_times.min()  # 下行段第一个交点
			var x_land: float = init_pos.x + init_vel.x * t_land
			landing_pos = Vector2(x_land, y_landing)
			print("Selected t_land: ", t_land, ", landing_pos: ", landing_pos)
	
	# 回退：如果无有效着陆点，计算完整抛物线（y = init_pos.y）
	if landing_pos == Vector2.INF:
		print("Fallback triggered: no valid landing point")
		y_landing = init_pos.y
		c = init_pos.y - y_landing  # c = 0
		discriminant = b * b - 4 * a * c
		print("Fallback discriminant: ", discriminant)
		if discriminant >= 0:
			var sqrt_disc: float = sqrt(discriminant)
			var t1: float = (-b + sqrt_disc) / (2 * a)
			var t2: float = (-b - sqrt_disc) / (2 * a)
			print("Fallback t1: ", t1, ", t2: ", t2)
			var valid_times: Array = []
			if t1 > t_apex + 0.0001:
				valid_times.append(t1)
			if t2 > t_apex + 0.0001:
				valid_times.append(t2)
			if not valid_times.is_empty():
				var t_land: float = valid_times.max()  # 完整抛物线
				var x_land: float = init_pos.x + init_vel.x * t_land
				landing_pos = Vector2(x_land, y_landing)
				print("Fallback landing_pos: ", landing_pos)
	
	# 确保返回有效结果
	if landing_pos == Vector2.INF:
		print("Error: No valid landing point found, returning apex as fallback")
		landing_pos = apex_pos
	
	return {
		"apex": apex_pos,
		"landing": landing_pos
	}
	
	
# 函数：计算抛物线的最高点和与直线的另一个交点（着陆点）
# 参数：
#   initial_pos: Vector2 - 初始坐标 (x0, y0)
#   velocity: Vector2 - 速度向量 (vx, vy)，vy 若向上发射则为负
#   gravity: float - 重力加速度 g（正值，向下）
#   k: float - 直线斜率
#   b: float - 直线截距
# 返回：Dictionary - 包含 "apex"（最高点坐标，Vector2）和 "landing"（着陆点坐标，Vector2）
# 若无有效着陆点，landing 返回 Vector2.ZERO；若无有效最高点，apex 返回 initial_pos
#static func calculate_intersection_point(initial_pos: Vector2, velocity: Vector2, gravity: float, k: float, b: float) -> Dictionary:
	#var x0 = initial_pos.x
	#var y0 = initial_pos.y
	#var vx = velocity.x
	#var vy = velocity.y
	#var g = gravity  # g > 0
	#
	## 初始化返回字典
	#var result = {"apex": initial_pos, "landing": Vector2.ZERO}
	#
	## 检查重力是否为 0
	#if g == 0:
		#return result  # 无重力，无抛物线
	#
	## 检查初始点是否在直线上
	#if abs(y0 - (k * x0 + b)) > 0.0001:  # 使用小容差避免浮点误差
		#return result  # 初始点不在直线上，无意义交点
	#
	## 计算最高点
	#var t_apex = -vy / g
	#if t_apex >= 0:
		#var x_apex = x0 + vx * t_apex
		#var y_apex = y0 + vy * t_apex + 0.5 * g * t_apex * t_apex
		#result["apex"] = Vector2(x_apex, y_apex)
	#
	## 计算着陆点（交点 C）
	#var numerator = -2 * (vy - k * vx)
	#var t_landing = numerator / g
	#
	#if t_landing > 0:  # 仅当 t > 0 时有效
		#var x_landing = x0 + vx * t_landing
		#var y_landing = y0 + vy * t_landing + 0.5 * g * t_landing * t_landing
		#result["landing"] = Vector2(x_landing, y_landing)
	#
	#return result
