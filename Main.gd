extends Node

func _ready():
	var editor = $ImageEditor
	var generator = $MeshGenerator
	var visual = $MeshInstance3D

	editor.connect("image_updated", Callable(generator, "update_mesh"))
	generator.connect("mesh_updated", func(mesh): visual.mesh = mesh)
