extends HSplitContainer

@onready var drawing_canvas = $SubViewportContainer/SubViewport/DrawingCanvas
@onready var model_viewer = $SubViewportContainer2/SubViewport/ModelViewer

func _process(delta):
	var image = drawing_canvas.image
	model_viewer.update_model(image)
