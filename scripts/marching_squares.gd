# marching_squares.gd
extends Node
class_name MarchingSquares


func generate_mesh(image: Image, threshold: float = 0.5, cell_size: float = 2.0) -> ArrayMesh:
	var width = image.get_width()
	var height = image.get_height()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)  # отрисовка сегментов линий

	# 1) Считываем поле яркости
	var field: Array = []
	for y in range(height):
		field.append([])
		for x in range(width):
			field[y].append(image.get_pixel(x, y).r)

	# 2) Проходим по каждой ячейке
	for y in range(height - 1):
		for x in range(width - 1):
			var a = field[y][x]
			var b = field[y][x + 1]
			var c = field[y + 1][x + 1]
			var d = field[y + 1][x]

			# 3) Вычисляем 4-битный индекс
			var config = int(a > threshold) \
						 | (int(b > threshold) << 1) \
						 | (int(c > threshold) << 2) \
						 | (int(d > threshold) << 3)

			# 4) Получаем сегменты линий с учётом инверсии Y
			var segments = marching_squares_lookup(config, x, y, field, threshold, cell_size, height)
			for seg in segments:
				st.add_vertex(Vector3(seg[0].x, seg[0].y, 0))
				st.add_vertex(Vector3(seg[1].x, seg[1].y, 0))

	# 5) Возвращаем готовый ArrayMesh
	return st.commit()
	
# Линейная интерполяция точки пересечения на ребрах ячейки
func interp(p1: Vector2, p2: Vector2, v1: float, v2: float, threshold: float) -> Vector2:
	var t = clamp((threshold - v1) / (v2 - v1), 0.0, 1.0) if (v2 != v1) else 0.5
	return p1.lerp(p2, t)


# Функция lookup с учётом перевёрнутой оси Y в Godot
func marching_squares_lookup(config: int, x: int, y: int, field: Array, threshold: float, cell_size: float, height: int) -> Array:
	var lines: Array = []

	# Значения яркости в углах ячейки
	var a = field[y][x]
	var b = field[y][x + 1]
	var c = field[y + 1][x + 1]
	var d = field[y + 1][x]

	# Перевёрнутая координата по Y (Godot: y растёт вниз)
	var inv_y0 = height - 1 - y
	var inv_y1 = height - 2 - y

	# Вычисляем точки пересечения на гранях
	var p_bottom    = interp(Vector2(x,   inv_y0) * cell_size, Vector2(x + 1, inv_y0) * cell_size, a, b, threshold)
	var p_right  = interp(Vector2(x + 1, inv_y0) * cell_size, Vector2(x + 1, inv_y1) * cell_size, b, c, threshold)
	var p_top  = interp(Vector2(x,   inv_y1) * cell_size, Vector2(x + 1, inv_y1) * cell_size, d, c, threshold)
	var p_left   = interp(Vector2(x,   inv_y0) * cell_size, Vector2(x,   inv_y1) * cell_size, a, d, threshold)

	# Ассимптотический decider для неоднозначных случаев
	var center = (a + b + c + d) * 0.25
	if config == 5:
		if center >= threshold:
			# «прямая» диагональ
			lines.append([p_left,   p_bottom])
			lines.append([p_top,    p_right])
		else:
			# «обратная» диагональ
			lines.append([p_top,    p_left])
			lines.append([p_bottom, p_right])

	if config == 10:
		if center >= threshold:
			lines.append([p_top,    p_right])
			lines.append([p_left,   p_bottom])
		else:
			lines.append([p_left,   p_top])
			lines.append([p_bottom, p_right])
	
	# Случаи 0 и 15 игнорируются
	# Остальные 14 случаев
	match config:
		1:
			lines.append([p_left,   p_bottom])
		2:
			lines.append([p_bottom, p_right])
		3:
			lines.append([p_left,   p_right])
		4:
			lines.append([p_top,    p_right])
		6:
			lines.append([p_top,    p_bottom])
		7:
			lines.append([p_top,    p_left])
		8:
			lines.append([p_top,    p_left])
		9:
			lines.append([p_top,    p_bottom])
		11:
			lines.append([p_top,    p_right])
		12:
			lines.append([p_left,   p_right])
		13:
			lines.append([p_bottom, p_right])
		14:
			lines.append([p_left,   p_bottom])
	return lines




func export_mesh_to_obj(mesh: ArrayMesh, path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	var indices: Array = arrays[Mesh.ARRAY_INDEX]

	for v in vertices:
		file.store_line("v %f %f %f" % [v.x, v.y, v.z])

	for vn in normals:
		file.store_line("vn %f %f %f" % [vn.x, vn.y, vn.z])

	for i in range(0, indices.size(), 3):
		var vi1 = indices[i] + 1
		var vi2 = indices[i + 1] + 1
		var vi3 = indices[i + 2] + 1
		file.store_line("f %d//%d %d//%d %d//%d" % [vi1, vi1, vi2, vi2, vi3, vi3])

	file.close()
