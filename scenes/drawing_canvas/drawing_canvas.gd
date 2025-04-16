extends Control

@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var slider: HSlider = $VBoxContainer/LineThicknessSlider
var image: Image
var image_texture: ImageTexture

var is_drawing: bool = false
var previous_pos: Vector2
var line_thickness: int = 4

func _ready():
	image = Image.create(512, 512, false, Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	image_texture = ImageTexture.create_from_image(image)
	texture_rect.texture = image_texture
	slider.value = line_thickness

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = texture_rect.get_local_mouse_position()
		if event.pressed:
			is_drawing = true
			previous_pos = local_pos
		else:
			is_drawing = false
	elif event is InputEventMouseMotion and is_drawing:
		var local_pos = texture_rect.get_local_mouse_position()
		_draw_line(previous_pos, local_pos)
		previous_pos = local_pos

func _draw_line(from_pos: Vector2, to_pos: Vector2):
	var points = _bresenham_line(from_pos, to_pos)
	for point in points:
		_draw_circle(point, line_thickness)
	image_texture.update(image)

func _bresenham_line(start: Vector2, end: Vector2) -> Array:
	var points = []
	var x0 = int(start.x)
	var y0 = int(start.y)
	var x1 = int(end.x)
	var y1 = int(end.y)
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	while true:
		points.append(Vector2(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	return points

func _draw_circle(center: Vector2, radius: int):
	var x0 = int(center.x)
	var y0 = int(center.y)
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px = x0 + x
				var py = y0 + y
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, Color.WHITE)


func _on_line_thickness_slider_value_changed(value):
	line_thickness = int(value)
