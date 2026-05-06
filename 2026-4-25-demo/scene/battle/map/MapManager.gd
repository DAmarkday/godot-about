extends Node2D

func center_map_with_camera(terrain_layer:TileMapLayer,camera:Camera2D) -> void:
	if not terrain_layer or not camera:
		return
	
	var used_rect: Rect2i = terrain_layer.get_used_rect()
	var tile_size: Vector2 = terrain_layer.tile_set.tile_size as Vector2
	var map_pixel_size: Vector2 = Vector2(used_rect.size) * tile_size  # 512,512
	
	# 计算地图真实中心（你确认是256,256）
	#var map_center = terrain_layer.to_global(
		#terrain_layer.map_to_local(used_rect.get_center())
	#)
	
	# 地图左上角（世界坐标）—— 即使 position 是 0,0 也推荐这么写
	var top_left_tile_center = terrain_layer.map_to_local(used_rect.position)
	var map_top_left: Vector2 = terrain_layer.to_global(
		top_left_tile_center - tile_size * 0.5
	)
	
	# 地图世界中心
	var map_center: Vector2 = map_top_left + map_pixel_size * 0.5
	
	# 屏幕中心
	var screen_center =get_viewport().get_visible_rect().size / 2.0
	
	# 关键：Camera位置 = 屏幕中心 - 地图中心
	camera.global_position =(map_center  - screen_center) 
	
	print("✅ 地图中心: ", map_center)
	print("✅ 屏幕中心: ", screen_center)
	print("✅ Camera 最终位置: ", camera.global_position)
	
	# ====================== 自动缩放 + UI留边 ======================
	#var ui_margin := Vector2(360, 200)   # 根据你的UI调整
	
	#var zoom_x = (get_viewport_rect().size.x - ui_margin.x) / map_pixel_size.x
	#var zoom_y = (get_viewport_rect().size.y - ui_margin.y) / map_pixel_size.y
	#var final_zoom = min(zoom_x, zoom_y, 1.2)
	
	#camera.zoom = Vector2(final_zoom, final_zoom)
	#print("✅ 最终 Zoom: ", final_zoom)
