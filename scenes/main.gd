extends HSplitContainer

@onready var drawing_canvas = $SubViewportContainer/SubViewport/DrawingCanvas
@onready var model_viewer = $SubViewportContainer2/SubViewport/ModelViewer

func _on_drawing_canvas_drawing_finished():
	var image = drawing_canvas.image
	model_viewer.update_model(image)
