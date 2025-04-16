# marching_squares.gd
extends Node

class_name MarchingSquares

func generate_mesh_from_image(image: Image) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Преобразуем изображение в массив значений
	var width = image.get_width()
	var height = image.get_height()
	var threshold = 0.5  # Пороговое значение для определения границы
	
	for y in range(height - 1):
		for x in range(width - 1):
			var square = []
			for dy in range(2):
				for dx in range(2):
					var color = image.get_pixel(x + dx, y + dy)
					var value = color.r  # Предполагаем, что изображение в оттенках серого
					square.append(value > threshold)
			
			# Определяем конфигурацию квадрата
			var config = int(square[0]) << 3 | int(square[1]) << 2 | int(square[3]) << 1 | int(square[2])
			
			# Добавляем треугольники в зависимости от конфигурации
			# Здесь необходимо реализовать соответствующие случаи
			
			# Пример для конфигурации 5
			if config == 5:
				var v1 = Vector3(x + 0.5, 0, y)
				var v2 = Vector3(x, 0, y + 0.5)
				var v3 = Vector3(x + 0.5, 0, y + 1)
				var v4 = Vector3(x + 1, 0, y + 0.5)
				
				st.add_triangle(v1, v2, v3)
				st.add_triangle(v1, v3, v4)
	
	st.generate_normals()
	mesh = st.commit()
	return mesh
