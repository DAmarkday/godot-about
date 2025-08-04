extends Node
class_name HealthSystem

# 信号
signal health_changed(current_health: int, max_health: int)
signal health_depleted

# 导出属性
@export var max_health: int = 5
@export var current_health: int = 5
@export var grid_height: float = 10.0  # 血量格子高度
@export var grid_spacing: float = 3.0  # 格子间距
@export var full_health_color: Color = Color.RED  # 满血格子颜色
@export var empty_health_color: Color = Color(0.3, 0.3, 0.3, 0.8)  # 空血格子颜色
@export var max_total_width: float = 50.0  # 血量条最大总宽度
@export var offset_y: float = 20.0  # 血量条相对于棋子底部的Y轴偏移
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.8)  # 背景颜色
@export var outer_border_color: Color = Color.WHITE  # 外边框颜色
@export var outer_border_width: float = 2.0  # 外边框宽度
@export var inner_border_color: Color = Color(0, 0, 0, 1.0)  # 内边框颜色
@export var inner_border_width: float = 2.0  # 内边框宽度

# 内部变量
var health_ui: Panel
var grid_width: float

func _ready() -> void:
	current_health = clamp(current_health, 0, max_health)
	calculate_grid_width()
	setup_health_ui()
	print("HealthSystem initialized for %s: max_health=%d, grid_width=%.2f, offset_y=%.2f" % [get_parent().name, max_health, grid_width, offset_y])

func calculate_grid_width() -> void:
	# 动态计算格子宽度，确保间距一致，最小4像素
	var total_spacing = grid_spacing * max(0, max_health - 1)  # 避免负间距
	grid_width = max((max_total_width - total_spacing) / max(max_health, 1), 4.0)
	print("Calculated grid_width for %s: %.2f, total_width: %.2f, spacing: %.2f" % [get_parent().name, grid_width, grid_width * max_health + total_spacing, grid_spacing])

func setup_health_ui() -> void:
	# 创建 UI 节点（使用 Panel 提供外边框和背景）
	if health_ui:
		health_ui.queue_free()
	health_ui = Panel.new()
	health_ui.name = "HealthUI"
	health_ui.visible = true  # 确保可见
	health_ui.z_index = 10  # 确保在其他节点之上
	add_child(health_ui, true)
	
	# 设置外边框和背景样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = background_color
	style_box.border_color = outer_border_color
	style_box.set_border_width_all(outer_border_width)
	health_ui.add_theme_stylebox_override("panel", style_box)
	
	# 设置血条位置和大小（相对于父节点局部坐标）
	var total_width = grid_width * max_health + grid_spacing * max(0, max_health - 1)
	var padding = inner_border_width + outer_border_width
	health_ui.position = Vector2(-total_width / 2.0 - padding, offset_y - padding)
	health_ui.size = Vector2(total_width + padding * 2, grid_height + padding * 2)
	
	# 添加内边框（ColorRect）
	var inner_border_rect = ColorRect.new()
	inner_border_rect.name = "InnerBorder"
	inner_border_rect.color = inner_border_color
	inner_border_rect.position = Vector2(outer_border_width, outer_border_width)
	inner_border_rect.size = Vector2(total_width + inner_border_width * 2, grid_height + inner_border_width * 2)
	health_ui.add_child(inner_border_rect)
	
	update_health_ui()
	print("Health UI created for %s at local position: %s, size: %s, background: %s, outer_border: %s, inner_border: %s" % [
		get_parent().name, health_ui.position, health_ui.size, background_color, outer_border_color, inner_border_color])
	if get_parent() is Node2D:
		print("Parent %s is Node2D, global position: %s" % [get_parent().name, get_parent().global_position])
	else:
		print("Warning: Parent %s is not Node2D, blood bar may not position correctly" % get_parent().name)

func update_health_ui() -> void:
	# 清空除内边框外的子节点
	for child in health_ui.get_children():
		if child.name != "InnerBorder":
			child.queue_free()
	
	# 计算血量条总宽度
	var total_width = grid_width * max_health + grid_spacing * max(0, max_health - 1)
	var padding = inner_border_width + outer_border_width
	var start_x = 0
	
	# 创建血量格子
	for i in range(max_health):
		var rect = ColorRect.new()
		rect.size = Vector2(grid_width, grid_height)
		rect.position = Vector2(start_x + i * (grid_width + grid_spacing) + padding, padding)
		rect.color = full_health_color if i < current_health else empty_health_color
		health_ui.add_child(rect)
		print("Grid %d for %s at position: %s" % [i, get_parent().name, rect.position])
	print("Health UI updated for %s: %d grids, total_width: %.2f, spacing: %.2f" % [get_parent().name, max_health, total_width, grid_spacing])

func take_damage(amount: int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	update_health_ui()
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0:
		emit_signal("health_depleted")
	print("Damage taken for %s: %d, Current health: %d" % [get_parent().name, amount, current_health])

func heal(amount: int) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	update_health_ui()
	emit_signal("health_changed", current_health, max_health)
	print("Healed for %s: %d, Current health: %d" % [get_parent().name, amount, current_health])

func set_max_health(new_max: int) -> void:
	max_health = max(1, new_max)
	current_health = clamp(current_health, 0, max_health)
	calculate_grid_width()
	setup_health_ui()  # 重新设置 UI 以更新大小和边框
	print("Max health set for %s: %d" % [get_parent().name, max_health])

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func _exit_tree() -> void:
	# 清理 UI
	if health_ui:
		health_ui.queue_free()
