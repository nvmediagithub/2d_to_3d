# marching_squares.gd
extends Node
class_name MarchingSquares

func interpolate(p1: Vector2, p2: Vector2, v1: float, v2: float, threshold: float) -> Vector2:
	if abs(v1 - v2) < 0.001:
		return (p1 + p2) / 2.0
	var t = (threshold - v1) / (v2 - v1)
	return p1.lerp(p2, t)

# Edge midpoint coordinates relative to cell origin
# Каждая конфигурация — список полигонов (каждый — список точек)
func generate_mesh_from_image(image: Image, z_offset := 0.0, thickness := 0.2) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var width := image.get_width()
	var height := image.get_height()
	var threshold := 0.5
	var center_offset = Vector3(width / 2.0, 0, height / 2.0)

	var segments = {
		0: [],
		1: [[3, 2, 3]],
		2: [[2, 1, 2]],
		3: [[3, 1, 2]],
		4: [[0, 1, 0]],
		5: [[3, 0, 1], [2, 3, 1]],
		6: [[0, 2, 1]],
		7: [[3, 2, 1, 0]],
		8: [[0, 3, 0]],
		9: [[0, 2, 3], [0, 1, 2]],
		10: [[0, 2, 1], [2, 3, 1]],
		11: [[3, 2, 1, 0]],
		12: [[3, 0, 1]],
		13: [[3, 0, 2], [2, 3, 1]],
		14: [[0, 2, 3]],
		15: [[0, 1, 2, 3]]
	}

	for y in range(height - 1):
		for x in range(width - 1):
			var v = [
				image.get_pixel(x, y).r,
				image.get_pixel(x + 1, y).r,
				image.get_pixel(x + 1, y + 1).r,
				image.get_pixel(x, y + 1).r
			]
			var config := 0
			for i in range(4):
				config |= int(v[i] > threshold) << (3 - i)

			var p = [
				Vector2(x, y),
				Vector2(x + 1, y),
				Vector2(x + 1, y + 1),
				Vector2(x, y + 1)
			]

			var edge_vertex := [
				interpolate(p[0], p[1], v[0], v[1], threshold),
				interpolate(p[1], p[2], v[1], v[2], threshold),
				interpolate(p[2], p[3], v[2], v[3], threshold),
				interpolate(p[3], p[0], v[3], v[0], threshold)
			]

			for poly in segments.get(config, []):
				if poly.size() < 3:
					continue
				var flat := PackedVector2Array()
				for idx in poly:
					flat.append(edge_vertex[idx])

				if Geometry2D.is_polygon_clockwise(flat):
					flat.reverse()

				var indices = Geometry2D.triangulate_polygon(flat)
				if indices.is_empty():
					print("Triangulation failed at config", config, "with points:", flat)
					continue

				for i in range(0, indices.size(), 3):
					var a = Vector3(flat[indices[i]].x, z_offset + thickness / 2.0, flat[indices[i]].y)
					var b = Vector3(flat[indices[i + 1]].x, z_offset + thickness / 2.0, flat[indices[i + 1]].y)
					var c = Vector3(flat[indices[i + 2]].x, z_offset + thickness / 2.0, flat[indices[i + 2]].y)
					st.set_normal(Vector3.UP)
					st.add_vertex(a - center_offset)
					st.add_vertex(b - center_offset)
					st.add_vertex(c - center_offset)

					st.set_normal(Vector3.DOWN)
					st.add_vertex(Vector3(a.x, z_offset - thickness / 2.0, a.z) - center_offset)
					st.add_vertex(Vector3(c.x, z_offset - thickness / 2.0, c.z) - center_offset)
					st.add_vertex(Vector3(b.x, z_offset - thickness / 2.0, b.z) - center_offset)

	st.index()
	st.generate_normals()
	return st.commit()

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
