extends Node3D
class_name MarchingSquaresFilled

@export var threshold: float = 0.5
@export var cell_size: float  = 2.0

func generate_mesh(image: Image) -> ArrayMesh:
	var width  = image.get_width()
	var height = image.get_height()
	var field  = []  # кэш яркостей

	for y in range(height):
		var row = []
		for x in range(width):
			row.append(image.get_pixel(x, y).r)
		field.append(row)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for y in range(height - 1):
		for x in range(width - 1):
			# 1) углы ячейки
			var a = field[y][x]
			var b = field[y][x + 1]
			var c = field[y + 1][x + 1]
			var d = field[y + 1][x]
			var config = int(a > threshold) \
					   | (int(b > threshold) << 1) \
					   | (int(c > threshold) << 2) \
					   | (int(d > threshold) << 3)
			if config == 0:
				continue  # либо всё пусто, либо всё заполнено (можно делать сплошной квад)

			# 2) вычисляем инвертированные Y для Godot
			var inv_y0 = height - 1 - y
			var inv_y1 = height - 2 - y

			# 3) точки пересечения
			var pB = interp(Vector2(x,   inv_y0), Vector2(x + 1, inv_y0), a, b)
			var pR = interp(Vector2(x + 1, inv_y0), Vector2(x + 1, inv_y1), b, c)
			var pT = interp(Vector2(x,   inv_y1), Vector2(x + 1, inv_y1), d, c)
			var pL = interp(Vector2(x,   inv_y0), Vector2(x,   inv_y1), a, d)

			# 4) собираем полигон: сначала «углы»
			var corners = [
				{ "val": a, "pt": Vector2(x,   inv_y0) },
				{ "val": b, "pt": Vector2(x+1, inv_y0) },
				{ "val": c, "pt": Vector2(x+1, inv_y1) },
				{ "val": d, "pt": Vector2(x,   inv_y1) }
			]
			var poly_pts = []
			for item in corners:
				if item.val > threshold:
					poly_pts.append(item.pt * cell_size)

			# 5) добавляем пересечения там, где «переключается» состояние
			if (a > threshold) != (b > threshold):
				poly_pts.append(pB * cell_size)
			if (b > threshold) != (c > threshold):
				poly_pts.append(pR * cell_size)
			if (c > threshold) != (d > threshold):
				poly_pts.append(pT * cell_size)
			if (d > threshold) != (a > threshold):
				poly_pts.append(pL * cell_size)

			# 6) сортируем по углу вокруг центра полигона
			if poly_pts.size() < 3:
				continue  # нечего заполнять
			var center = Vector2.ZERO
			for p in poly_pts:
				center += p
			center /= poly_pts.size()

			poly_pts.sort_custom(func(a, b):
				var ang_a = atan2(a.y - center.y, a.x - center.x)
				var ang_b = atan2(b.y - center.y, b.x - center.x)
				return ang_a < ang_b
			)

			# 7) триангулируем веером
			for i in range(poly_pts.size()):
				var j = (i + 1) % poly_pts.size()
				st.add_vertex(Vector3(center.x, center.y, 0))
				st.add_vertex(Vector3(poly_pts[i].x, poly_pts[i].y, 0))
				st.add_vertex(Vector3(poly_pts[j].x, poly_pts[j].y, 0))

	return st.commit()



# линейная интерполяция на рёбрах
func interp(p1: Vector2, p2: Vector2, v1: float, v2: float) -> Vector2:
	var t =  0.5 if (v2 == v1) else clamp((threshold - v1) / (v2 - v1), 0.0, 1.0)
	return p1.lerp(p2, t)
