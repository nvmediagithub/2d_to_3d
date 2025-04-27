# model_viewer.gd
extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var marching_squares = MarchingSquaresFilled.new()

func update_model(image: Image):
	var mesh = marching_squares.generate_mesh(image)
	mesh_instance.mesh = mesh
