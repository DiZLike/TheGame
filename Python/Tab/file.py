func find_respawn_point() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return Vector2.ZERO
	
	# Принудительно обновляем позицию камеры
	camera.reset_smoothing()
	if camera.has_method("force_update_scroll"):
		camera.force_update_scroll()
	
	var camera_center := camera.get_screen_center_position()  # Более точный метод
	var screen_size := get_viewport().get_visible_rect().size
	
	# Добавляем отступы, чтобы не респауниться вплотную к краю
	var edge_margin := 80.0
	var left_limit := camera_center.x - screen_size.x / 2 + edge_margin
	var right_limit := camera_center.x + screen_size.x / 2 - edge_margin
	
	var check_x := left_limit
	var check_y := camera_center.y  # Лучше бить с центра камеры вниз
	
	respawn_ray.enabled = true
	respawn_ray.target_position = Vector2(0, 500)  # Длина луча
	
	while check_x <= right_limit:
		respawn_ray.global_position = Vector2(check_x, check_y)
		respawn_ray.force_raycast_update()
		
		if respawn_ray.is_colliding():
			var hit_point := respawn_ray.get_collision_point()
			var player_height = 64.0  # Замени на свою высоту игрока
			var respawn_y = hit_point.y - player_height + 5
			
			# Защита от выхода за верх экрана
			var min_y = camera_center.y - screen_size.y / 2 + 50
			if respawn_y < min_y:
				respawn_y = min_y
			
			respawn_ray.enabled = false
			return Vector2(check_x, respawn_y)
		
		check_x += RESPAWN_SEARCH_STEP
	
	respawn_ray.enabled = false
	# Fallback строго в центре экрана
	return Vector2(camera_center.x, camera_center.y + screen_size.y / 4)