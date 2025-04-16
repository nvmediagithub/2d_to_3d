# model_viewer.gd
extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var marching_squares = MarchingSquares.new()

func update_model(image: Image):
	var mesh = marching_squares.generate_mesh_from_image(image)
	mesh_instance.mesh = mesh
