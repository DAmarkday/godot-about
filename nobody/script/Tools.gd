extends Node
class_name Tools

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
	var y_landing: float = init_pos.y + random_offset
	
	# 限制 y_landing 在抛物线可达范围内
	var max_y_drop: float = abs(apex_pos.y - init_pos.y) + 100.0  # 允许额外下降
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
