extends Node

signal mesh_updated(mesh: ArrayMesh)

@onready var marching = preload("res://Generation/MarchingSquares.gd").new()

func update_mesh(image: Image):
	var segments = marching.extract_segments(image)
	var contour = marching.to_flat_array(segments)
	var mesh = generate_mesh(contour, segments)
	emit_signal("mesh_updated", mesh)

func generate_mesh(contour: PackedVector2Array, segments: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center = calculate_center(contour)
	for i in range(0, contour.size(), 2):
		var p1: Vector2 = contour[i] - center
		var p2: Vector2 = contour[i + 1] - center
		var v0 = Vector3(p1.x, p1.y, 0)
		var v1 = Vector3(p2.x, p2.y, 0)
		var v2 = Vector3(p2.x, p2.y, 10)
		var v3 = Vector3(p1.x, p1.y, 10)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(v2)
		st.add_vertex(v0)
		st.add_vertex(v2)
		st.add_vertex(v3)
	var polygons = marching.chain_all(segments)
	for poly in polygons:
		var indices = Geometry2D.triangulate_polygon(poly)
		for i in range(0, indices.size(), 3):
			var a = poly[indices[i]] - center
			var b = poly[indices[i+1]] - center
			var c = poly[indices[i+2]] - center
			st.add_vertex(Vector3(a.x, a.y, 0))
			st.add_vertex(Vector3(b.x, b.y, 0))
			st.add_vertex(Vector3(c.x, c.y, 0))
			st.add_vertex(Vector3(c.x, c.y, 10))
			st.add_vertex(Vector3(b.x, b.y, 10))
			st.add_vertex(Vector3(a.x, a.y, 10))
	return st.commit()

func calculate_center(arr: PackedVector2Array) -> Vector2:
	var min_p = Vector2(INF, INF)
	var max_p = Vector2(-INF, -INF)
	for p in arr:
		min_p.x = min(min_p.x, p.x)
		min_p.y = min(min_p.y, p.y)
		max_p.x = max(max_p.x, p.x)
		max_p.y = max(max_p.y, p.y)
	return (min_p + max_p) / 2
