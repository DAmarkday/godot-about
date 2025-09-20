extends Node2D
@onready var line: Line2D = $Line2D

func update_detection_range(center: Vector2, drange: float = 100,color:Color = Color(255, 255, 255, 0.1)) -> void:
	# 将全局位置转换为 Line2D 的局部坐标
	var local_center = line.to_local(center)
	var points: PackedVector2Array = []
	var segments = 64  # 圆形分段数
	for i in range(segments):
		var angle = i * 2.0 * PI / segments
		points.append(local_center + Vector2(cos(angle), sin(angle)) * drange)
	points.append(points[0])  # 闭合圆形
	line.points = points
	line.width = 2.0
	line.default_color =color  
