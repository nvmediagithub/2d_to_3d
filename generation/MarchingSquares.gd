extends Resource

func extract_segments(image: Image) -> Array:
	return []  # Заглушка

func to_flat_array(segments: Array) -> PackedVector2Array:
	var arr = PackedVector2Array()
	for seg in segments:
		arr.append(seg[0])
		arr.append(seg[1])
	return arr

func chain_all(segments: Array) -> Array:
	return []  # Заглушка
