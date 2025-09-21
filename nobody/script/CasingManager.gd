extends Node

# 预加载子弹壳场景
var casing_scene: PackedScene = preload("res://scene/bullet/bulletCasing/BulletCasing.tscn")
var pool_size: int = 10
var casing_pool: Array[Node2D] = []
var available_casings: Array[Node2D] = []

func create():
	if not casing_scene:
		push_error("Casing scene not set! Please assign in inspector.")
		return
	
	# 初始化对象池
	for i in pool_size:
		var casing = casing_scene.instantiate()
		if is_instance_valid(casing):
			casing.visible = false
			casing.process_mode = Node.PROCESS_MODE_DISABLED
			GameManager.getMapInstance().addEntityToViewer(casing)
			# 连接 finished 信号
			casing.connect("finished", Callable(self, "recycle_casing").bind(casing))
			casing_pool.append(casing)
			available_casings.append(casing)
		else:
			push_error("Failed to instantiate casing scene!")

# 弹出壳体
func eject_casing(muzzle_position: Vector2, player_position: Vector2, player_direction: Vector2):
	if available_casings.is_empty():
		print("壳体池已满，跳过弹出")
		return

	var casing = available_casings.pop_back()
	if not is_instance_valid(casing):
		push_error("Invalid casing in pool!")
		return

	# 设置壳体
	casing.setup(muzzle_position, player_position, player_direction)
	casing.visible = true
	casing.process_mode = Node.PROCESS_MODE_INHERIT

# 回收壳体
func recycle_casing(casing: Node2D):
	if not is_instance_valid(casing):
		push_error("Trying to recycle invalid casing!")
		return

	casing.visible = false
	casing.process_mode = Node.PROCESS_MODE_DISABLED
	casing.reset()  # 调用 BulletCasing 的 reset 方法
	available_casings.append(casing)
