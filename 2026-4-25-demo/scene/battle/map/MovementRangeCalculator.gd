extends RefCounted
class_name MovementRangeCalculator

## 移动范围计算器 - 基于 AStarGrid2D
## 计算棋子可移动范围，考虑地形成本和障碍

var astar: AStarGrid2D
var map_data: MapData


func _init(data: MapData) -> void:
	map_data = data
	_setup_astar()


## 初始化 AStarGrid2D
func _setup_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, map_data.width, map_data.height)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER  # 只允许上下左右移动
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	# 更新所有格子的可通行性和成本
	astar.update()
	
	for x in range(map_data.width):
		for y in range(map_data.height):
			var cell = Vector2i(x, y)
			var cost = map_data.get_move_cost(cell)
			
			if cost >= INF:
				astar.set_point_solid(cell, true)  # 不可通行
			else:
				astar.set_point_solid(cell, false)
				astar.set_point_weight_scale(cell, cost)  # 设置移动成本


## 计算可移动范围（返回所有可达格子）
func calculate_movement_range(start_cell: Vector2i, max_movement: int, occupied_cells: Array[Vector2i] = []) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited = {}
	var queue = [{
		"cell": start_cell,
		"cost": 0.0
	}]
	
	visited[start_cell] = 0.0
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_cell = current.cell
		var current_cost = current.cost
		
		# 检查四个方向
		for dir in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var neighbor = current_cell + dir
			
			# 检查是否在范围内
			if not map_data.is_in_bounds(neighbor):
				continue
			
			# 检查是否被其他棋子占据
			if neighbor in occupied_cells and neighbor != start_cell:
				continue
			
			# 计算移动到邻居的成本
			var move_cost = map_data.get_move_cost(neighbor)
			if move_cost >= INF:
				continue
			
			var new_cost = current_cost + move_cost
			
			# 检查是否超过移动力
			if new_cost > max_movement:
				continue
			
			# 检查是否已访问过（且成本更低）
			if visited.has(neighbor) and visited[neighbor] <= new_cost:
				continue
			
			visited[neighbor] = new_cost
			queue.append({"cell": neighbor, "cost": new_cost})
			
			if neighbor != start_cell:
				reachable.append(neighbor)
	
	return reachable


## 计算两点之间的最短路径
func calculate_path(from: Vector2i, to: Vector2i, occupied_cells: Array[Vector2i] = []) -> Array[Vector2i]:
	# 临时设置占据格子为不可通行
	for cell in occupied_cells:
		if cell != from and cell != to:
			astar.set_point_solid(cell, true)
	
	var path_points = astar.get_id_path(from, to)
	var path: Array[Vector2i] = []
	path.assign(path_points)
	
	# 恢复占据格子的状态
	for cell in occupied_cells:
		if cell != from and cell != to:
			var cost = map_data.get_move_cost(cell)
			astar.set_point_solid(cell, cost >= INF)
	
	return path


## 计算路径总成本
func calculate_path_cost(path: Array[Vector2i]) -> float:
	var total_cost = 0.0
	for cell in path:
		total_cost += map_data.get_move_cost(cell)
	return total_cost


## 检查格子是否在移动范围内
func is_in_movement_range(start_cell: Vector2i, target_cell: Vector2i, max_movement: int, occupied_cells: Array[Vector2i] = []) -> bool:
	var path = calculate_path(start_cell, target_cell, occupied_cells)
	if path.is_empty():
		return false
	
	var cost = calculate_path_cost(path)
	return cost <= max_movement


## 更新地图数据（当地形改变时）
func update_map_data(new_map_data: MapData) -> void:
	map_data = new_map_data
	_setup_astar()
