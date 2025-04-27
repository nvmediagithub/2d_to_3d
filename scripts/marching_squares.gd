# marching_squares.gd
extends Node
class_name MarchingSquares


# Вспомогательная функция: возвращает 1 если пиксель ярче порога, иначе 0
func get_value(x, y, image, threshold):
	var color = image.get_pixel(x, y)
	return color.r > threshold

# Вспомогательная функция: интерполяция между двумя точками
func lerp_point(p1: Vector3, p2: Vector3) -> Vector3:
	return (p1 + p2) * 0.5


# Получить значение внутри / снаружи
func val(x, y, image, threshold):
	return image.get_pixel(x, y).r > threshold

# Быстрый векторный вызов
func v(x, y, z_offset, center_offset):
	return Vector3(x, z_offset, y) - center_offset
		
func generate_mesh_from_image(image: Image, threshold: float = 0.5, cell_size: float = 1.0) -> ArrayMesh:
	var width = image.get_width()
	var height = image.get_height()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Предварительная обработка: получение значений яркости пикселей
	var field = []
	for y in range(height):
		field.append([])
		for x in range(width):
			var color = image.get_pixel(x, y)
			var value = color.r  # Предполагается, что изображение в градациях серого
			field[y].append(value)

	# Проход по каждой ячейке сетки
	for y in range(height - 1):
		for x in range(width - 1):
			# Получение значений в вершинах ячейки
			var top_left = field[y][x]
			var top_right = field[y][x + 1]
			var bottom_right = field[y + 1][x + 1]
			var bottom_left = field[y + 1][x]

			# Определение конфигурации ячейки
			var config = 0
			if top_left > threshold:
				config |= 1
			if top_right > threshold:
				config |= 2
			if bottom_right > threshold:
				config |= 4
			if bottom_left > threshold:
				config |= 8

			# Получение соответствующих линий из таблицы конфигураций
			var lines = marching_squares_lookup(config, x, y, field, threshold, cell_size)
			for triangle in lines:
				for vertex in triangle:
					st.add_vertex(Vector3(vertex[0], vertex[1], 0))
					
	st.index()
	st.generate_normals()
	export_mesh_to_obj(st.commit(), 'TT.OBJ')
	return st.commit()

func marching_squares_lookup(config: int, x: int, y: int, field: Array, threshold: float, cell_size: float) -> Array:
	var triangles = []
	
	# Определение значений в вершинах ячейки
	var top_left = field[y][x]
	var top_right = field[y][x + 1]
	var bottom_right = field[y + 1][x + 1]
	var bottom_left = field[y + 1][x]
	
	# Вычисление позиций точек пересечения изолинии с границами ячейки
	var top = Vector2(x + 0.5, y)
	var right = Vector2(x + 1, y + 0.5)
	var bottom = Vector2(x + 0.5, y + 1)
	var left = Vector2(x, y + 0.5)
	
	# Преобразование координат в мировое пространство
	top *= cell_size
	right *= cell_size
	bottom *= cell_size
	left *= cell_size
	
	match config:
		0, 15:
			pass  # Нет изолинии
		1, 14:
			triangles.append([bottom, left, bottom])
		2, 13:
			triangles.append([right, bottom, right])
		3, 12:
			triangles.append([right, left, right])
		4, 11:
			triangles.append([top, right, top])
		5:
			triangles.append([top, right, bottom])
			triangles.append([bottom, left, top])
		6, 9:
			triangles.append([top, bottom, top])
		7, 8:
			triangles.append([top, left, top])
		10:
			triangles.append([top, right, bottom])
			triangles.append([bottom, left, top])
		_:
			pass  # Обработка других конфигураций при необходимости
	
	return triangles




# Edge midpoint coordinates relative to cell origin
# Каждая конфигурация — список полигонов (каждый — список точек)
#func generate_mesh_from_image(image: Image, z_offset := 0.0, thickness := 0.2) -> ArrayMesh:
	#var mesh := ArrayMesh.new()
	#var st := SurfaceTool.new()
	#st.begin(Mesh.PRIMITIVE_TRIANGLES)
#
	#var width := image.get_width()
	#var height := image.get_height()
	#var threshold := 0.5
	#var center_offset = Vector3(width / 2.0, 0, height / 2.0)
#
	#var segments = {
		#0: [],
		#1: [[3, 2, 3]],
		#2: [[2, 1, 2]],
		#3: [[3, 1, 2]],
		#4: [[0, 1, 0]],
		#5: [[3, 0, 1], [2, 3, 1]],
		#6: [[0, 2, 1]],
		#7: [[3, 2, 1], [3, 1, 0]],
		#8: [[0, 3, 0]],
		#9: [[0, 2, 3], [0, 1, 2]],
		#10: [[0, 2, 1], [2, 3, 1]],
		#11: [[3, 2, 1], [3, 1, 0]],
		#12: [[3, 0, 1]],
		#13: [[3, 0, 2], [2, 3, 1]],
		#14: [[0, 2, 3]],
		#15: [[0, 1, 2], [0, 2, 3]]
	#}
#
	#for y in range(height - 1):
		#for x in range(width - 1):
			#var v = [
				#image.get_pixel(x, y).r,
				#image.get_pixel(x + 1, y).r,
				#image.get_pixel(x + 1, y + 1).r,
				#image.get_pixel(x, y + 1).r
			#]
			#var config := 0
			#for i in range(4):
				#config |= int(v[i] >= threshold) << (3 - i)
#
			## Вершины квадрата (по часовой)
			#var p = [
				#Vector2(x, y),
				#Vector2(x + 1, y),
				#Vector2(x + 1, y + 1),
				#Vector2(x, y + 1)
			#]
#
			## Эджи
			#var edge_vertex := [
				#interpolate(p[0], p[1], v[0], v[1], threshold), # 0
				#interpolate(p[1], p[2], v[1], v[2], threshold), # 1
				#interpolate(p[2], p[3], v[2], v[3], threshold), # 2
				#interpolate(p[3], p[0], v[3], v[0], threshold)  # 3
			#]
#
			## Обработка неоднозначных конфигураций
			#var local_segments = segments.get(config, [])
			#if config == 5 or config == 10:
				#var center_value : float = (v[0] + v[1] + v[2] + v[3]) / 4.0
				#var is_center_high : bool = center_value >= threshold
#
				#if config == 5:
					#if is_center_high:
						#local_segments = [[0, 3, 1]] # Диагональ ↘
					#else:
						#local_segments = [[2, 3, 1]] # Диагональ ↗
				#elif config == 10:
					#if is_center_high:
						#local_segments = [[0, 2, 1]]  # Диагональ ↘
					#else:
						#local_segments = [[0, 2, 3]]  # Диагональ ↗
#
				##print("Ambiguous case", config, "at", x, y, "-> using", is_center_high ? "↘" : "↗")
#
			#for poly in local_segments:
				#if poly.size() < 3:
					#continue
				#var flat := PackedVector2Array()
				#for idx in poly:
					#flat.append(edge_vertex[idx])
#
				#if Geometry2D.is_polygon_clockwise(flat):
					#flat.reverse()
#
				#var indices = Geometry2D.triangulate_polygon(flat)
				#if indices.is_empty():
					#print("Triangulation failed at config", config, "with points:", flat)
					#continue
#
				#for i in range(0, indices.size(), 3):
					#var a = Vector3(flat[indices[i]].x, z_offset + thickness / 2.0, flat[indices[i]].y)
					#var b = Vector3(flat[indices[i + 1]].x, z_offset + thickness / 2.0, flat[indices[i + 1]].y)
					#var c = Vector3(flat[indices[i + 2]].x, z_offset + thickness / 2.0, flat[indices[i + 2]].y)
					#st.set_normal(Vector3.UP)
					#st.add_vertex(a - center_offset)
					#st.add_vertex(b - center_offset)
					#st.add_vertex(c - center_offset)
#
					#st.set_normal(Vector3.DOWN)
					#st.add_vertex(Vector3(a.x, z_offset - thickness / 2.0, a.z) - center_offset)
					#st.add_vertex(Vector3(c.x, z_offset - thickness / 2.0, c.z) - center_offset)
					#st.add_vertex(Vector3(b.x, z_offset - thickness / 2.0, b.z) - center_offset)
#
#
	#st.index()
	#st.generate_normals()
	#export_mesh_to_obj(st.commit(), 't.OBJ')
	#return st.commit()

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
