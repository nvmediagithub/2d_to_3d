extends TextureRect

signal image_updated(new_img: Image)

var image: Image
var image_texture: ImageTexture

var brush_size: int = 60
var brush_color: Color = Color(1, 1, 1, 1)

func _ready():
	# Устанавливаем фильтр мыши для обработки событий ввода
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Отложенная инициализация изображения
	call_deferred("_initialize_image")

func _initialize_image():
	# Проверяем текущие размеры TextureRect
	if size.x > 0 and size.y > 0:
		# Создаём изображение с размерами TextureRect и форматом RGBA8
		image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
		# Заполняем изображение белым цветом
		image.fill(Color(0, 0, 0, 1))
		# Создаём ImageTexture из изображения
		image_texture = ImageTexture.create_from_image(image)
		texture = image_texture
	else:
		print("Размеры TextureRect не установлены.")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var local_pos = get_local_mouse_position()
		_draw_at_position(local_pos)
		_update_texture()
		
		# После изменений можно вызывать функцию обновления 3D-модели, например через сигнал
		emit_signal("image_updated", image)

func _draw_at_position(pos: Vector2) -> void:
	# Рисуем кистью – устанавливаем brush_color для пикселей внутри круга кисти
	for x in range(-brush_size, brush_size + 1):
		for y in range(-brush_size, brush_size + 1):
			var offset = Vector2(x, y)
			if offset.length() <= brush_size:
				var draw_pos = pos + offset
				if draw_pos.x >= 0 and draw_pos.x < image.get_width() and draw_pos.y >= 0 and draw_pos.y < image.get_height():
					image.set_pixelv(draw_pos, brush_color)

func _update_texture() -> void:
	# Обновляем текстуру с учётом изменений в изображении
	image_texture.update(image)
	texture = image_texture
