extends Node3D

# Подключаем сигнал image_updated из ImageEditor (например, TextureRect)
func _ready():
	var image_editor = get_node("../../../TextureRect")
	image_editor.connect("image_updated", Callable(self, "_on_ImageEditor_image_updated"))
	set_process(true)

# Обработчик сигнала, получающего обновлённое изображение
func _on_ImageEditor_image_updated(new_img: Image) -> void:
	var segments_array = extract_contour(new_img)
	# Преобразуем массив сегментов (каждый сегмент – массив из двух Vector2)
	# в один плоский PackedVector2Array, где каждая пара точек – один сегмент.
	var contour = PackedVector2Array()
	for seg in segments_array:
		contour.append(seg[0])
		contour.append(seg[1])
	print("Количество сегментов контура: ", contour.size() / 2)
	var mesh: ArrayMesh = generate_extruded_mesh(contour, 10, segments_array)
	$MeshInstance3D.mesh = mesh

# Реализация алгоритма Marching Squares
# Возвращает массив сегментов: каждый сегмент – массив из двух точек (Vector2)

func extract_contour(image: Image) -> Array:
	var threshold: float = 0.5
	var segments = []
	# Обходим всю область, включая границы, используя безопасное получение пикселей
	var w = image.get_width()
	var h = image.get_height()
	# Таблица переходов для каждой ячейки (размер ячейки = 1)
	var lookup = {
		0: [],
		1: [[Vector2(0, 0.5), Vector2(0.5, 1)]],
		2: [[Vector2(0.5, 1), Vector2(1, 0.5)]],
		3: [[Vector2(0, 0.5), Vector2(1, 0.5)]],
		4: [[Vector2(0.5, 0), Vector2(1, 0.5)]],
		5: [[Vector2(0.5, 0), Vector2(0, 0.5)], [Vector2(0.5, 1), Vector2(1, 0.5)]],
		6: [[Vector2(0.5, 0), Vector2(0.5, 1)]],
		7: [[Vector2(0.5, 0), Vector2(0, 0.5)]],
		8: [[Vector2(0.5, 0), Vector2(0, 0.5)]],
		9: [[Vector2(0.5, 0), Vector2(0.5, 1)]],
		10: [[Vector2(0.5, 0), Vector2(1, 0.5)], [Vector2(0, 0.5), Vector2(0.5, 1)]],
		11: [[Vector2(0.5, 0), Vector2(1, 0.5)]],
		12: [[Vector2(0, 0.5), Vector2(1, 0.5)]],
		13: [[Vector2(0.5, 1), Vector2(1, 0.5)]],
		14: [[Vector2(0, 0.5), Vector2(0.5, 1)]],
		15: []
	}
	# Обходим ячейки: теперь используем диапазон от 0 до w - 1, 0 до h - 1,
	# но при получении пикселей задействуем функцию get_pixel_safe
	for x in range(w - 1):
		for y in range(h - 1):
			var top_left = 1 if get_pixel_safe(image, x, y).r >= threshold else 0
			var top_right = 1 if get_pixel_safe(image, x + 1, y).r >= threshold else 0
			var bottom_rigth = 1 if get_pixel_safe(image, x + 1, y + 1).r >= threshold else 0
			var bottom_left = 1 if get_pixel_safe(image, x, y + 1).r >= threshold else 0
			var state = (top_left << 3) | (top_right << 2) | (bottom_rigth << 1) | bottom_left
			var cell_segments = lookup[state]
			for seg in cell_segments:
				var p1 = seg[0] + Vector2(x, y)
				var p2 = seg[1] + Vector2(x, y)
				segments.append([p1, p2])
	return segments

	# Округление для стабильности
func round_vec2(v: Vector2) -> Vector2:
	return Vector2(round(v.x * 1000) / 1000, round(v.y * 1000) / 1000)
	
func chain_all_segments(segments_array: Array) -> Array:
	var adjacency := {}
	var used_pairs := {}
	var all_points := {}

	for seg in segments_array:
		var a = round_vec2(seg[0])
		var b = round_vec2(seg[1])
		all_points[a] = true
		all_points[b] = true

		if not adjacency.has(a):
			adjacency[a] = []
		if not adjacency.has(b):
			adjacency[b] = []

		if not used_pairs.has(a):
			used_pairs[a] = {}
		if not used_pairs.has(b):
			used_pairs[b] = {}

		if not used_pairs[a].has(b):
			adjacency[a].append(b)
			used_pairs[a][b] = true
		if not used_pairs[b].has(a):
			adjacency[b].append(a)
			used_pairs[b][a] = true

	var visited := {}
	var contours := []

	# Находим все незамкнутые группы точек
	for point in all_points.keys():
		if visited.has(point):
			continue
		var polygon := PackedVector2Array()
		var current = point
		polygon.append(current)
		visited[current] = true

		while true:
			var found = false
			for n in adjacency[current]:
				if not visited.has(n):
					polygon.append(n)
					visited[n] = true
					current = n
					found = true
					break
			if not found:
				break
			if polygon.size() > 2 and polygon[0].distance_to(polygon[-1]) < 0.01:
				break
		if polygon.size() >= 3:
			contours.append(polygon)

	return contours

# Функция для объединения отдельных сегментов в один замкнутый контур.
# Очень упрощенная реализация: начинается с первого сегмента и пытается цеплять следующие.
func chain_segments(segments_array: Array) -> PackedVector2Array:
	var adjacency = {}
	for seg in segments_array:
		var a = seg[0]
		var b = seg[1]
		if not adjacency.has(a):
			adjacency[a] = []
		if not adjacency.has(b):
			adjacency[b] = []
		adjacency[a].append(b)
		adjacency[b].append(a)

	var polygon = PackedVector2Array()
	if adjacency.size() == 0:
		return polygon
	
	var start = adjacency.keys()[0]
	var current = start
	var visited = {}
	visited[current] = true
	polygon.append(current)

	while true:
		var neighbors = adjacency[current]
		var next = null
		for n in neighbors:
			if not visited.has(n):
				next = n
				break
		if next == null:
			break
		polygon.append(next)
		visited[next] = true
		current = next
		if current == start:
			break

	return polygon

# Генерация 3D-меша путём экструзии полученного контура.
# flat_contour - плоский массив точек стенок (каждые 2 точки = один сегмент),
# segments_array - исходный массив сегментов для формирования замкнутого контура.
# Добавлены крышка (верхняя грань) и дон (нижняя грань).
func generate_extruded_mesh(contour: PackedVector2Array, height: float, segments_array: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Вычисляем bounding box для центрирования
	var min_point = Vector2(INF, INF)
	var max_point = Vector2(-INF, -INF)
	for p in contour:
		min_point.x = min(min_point.x, p.x)
		min_point.y = min(min_point.y, p.y)
		max_point.x = max(max_point.x, p.x)
		max_point.y = max(max_point.y, p.y)
	var center = (min_point + max_point) * 0.5
	
	# Генерация стенок (экструзия сегментов)
	for i in range(contour.size() / 2):
		var p1: Vector2 = contour[i * 2] - center
		var p2: Vector2 = contour[i * 2 + 1] - center
		var v0 = Vector3(p1.x, p1.y, 0)
		var v1 = Vector3(p2.x, p2.y, 0)
		var v2 = Vector3(p2.x, p2.y, height)
		var v3 = Vector3(p1.x, p1.y, height)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(v2)
		st.add_vertex(v0)
		st.add_vertex(v2)
		st.add_vertex(v3)
	
	# Формируем замкнутый контур для крышки и дна
	var polygons = chain_all_segments(segments_array)
	for polygon in polygons:
		if polygon.size() >= 3:
			var indices = Geometry2D.triangulate_polygon(polygon)
			for i in range(0, indices.size(), 3):
				# Дон
				var v0 = Vector3(polygon[indices[i]].x - center.x, polygon[indices[i]].y - center.y, 0)
				var v1 = Vector3(polygon[indices[i + 1]].x - center.x, polygon[indices[i + 1]].y - center.y, 0)
				var v2 = Vector3(polygon[indices[i + 2]].x - center.x, polygon[indices[i + 2]].y - center.y, 0)
				st.add_vertex(v0)
				st.add_vertex(v1)
				st.add_vertex(v2)

			# Крышка
			var indices_top = indices.duplicate()
			indices_top.reverse()
			for i in range(0, indices_top.size(), 3):
				var v0 = Vector3(polygon[indices_top[i]].x - center.x, polygon[indices_top[i]].y - center.y, height)
				var v1 = Vector3(polygon[indices_top[i + 1]].x - center.x, polygon[indices_top[i + 1]].y - center.y, height)
				var v2 = Vector3(polygon[indices_top[i + 2]].x - center.x, polygon[indices_top[i + 2]].y - center.y, height)
				st.add_vertex(v0)
				st.add_vertex(v1)
				st.add_vertex(v2)
	
	return st.commit()

# Безопасное получение пикселя: если (x, y) вне границ, возвращаем чёрный цвет.
func get_pixel_safe(image: Image, x: int, y: int) -> Color:
	if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
		return Color(0, 0, 0, 1)  # фон считается чёрным
	return image.get_pixel(x, y)

# Добавляем вращение меша для визуального эффекта
var rotation_speed: Vector3 = Vector3(0.0, 1.0, 0.0)

func _process(delta: float) -> void:
	$MeshInstance3D.rotate_y(delta)
	$MeshInstance3D.rotate_z(delta)
