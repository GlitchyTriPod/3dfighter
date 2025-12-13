extends "res://addons/delta_rollback/MessageSerializer.gd"

const input_path_mapping := {
	"/root/TestingRollbackEnetConnection/SubViewportContainer/SubViewport/Stage/Chars/atro4": 1,
	"/root/TestingRollbackEnetConnection/SubViewportContainer/SubViewport/Stage/Chars/atro5": 2
}

enum HEADER_FLAGS {
	HAS_INPUT_DIRECTIONAL = 0x01,
	HAS_INPUT_BUTTON = 0x02
}

enum BUTTON_FLAGS {
	P = 0x01,
	K = 0x02,
	A = 0x04
}

var input_path_mapping_reverse := {}

func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)

	buffer.put_u32(all_input["$"])
	buffer.put_u8(all_input.size() - 1)

	for path in all_input:
		if path == "$":
			continue
		buffer.put_u8(input_path_mapping[path])
		
		var header := 0

		var input = all_input[path]
		if input.has("input_directional"):
			header |= HEADER_FLAGS.HAS_INPUT_DIRECTIONAL
		if input.has("input_button"):
			header |= HEADER_FLAGS.HAS_INPUT_BUTTON

		buffer.put_u8(header)

		if input.has("input_directional"):
			var input_vector: Vector2i = input["input_directional"]
			buffer.put_8(input_vector.x)
			buffer.put_8(input_vector.y)

		if input.has("input_button"):
			var buttons: Dictionary = input["input_button"]
			var button_val := 0
			if buttons.has("p"):
				button_val |= BUTTON_FLAGS.P
			if buttons.has("k"):
				button_val |= BUTTON_FLAGS.K
			if buttons.has("a"):
				button_val |= BUTTON_FLAGS.A
			
			buffer.put_u8(button_val)

	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)

	var all_input := {}

	all_input["$"] = buffer.get_u32()

	var input_count := buffer.get_u8()
	if input_count == 0:
		return all_input

	var path = input_path_mapping_reverse[buffer.get_u8()]
	var input := {}

	var header = buffer.get_u8()

	if header & HEADER_FLAGS.HAS_INPUT_DIRECTIONAL:
		input["input_directional"] = Vector2i(buffer.get_8(), buffer.get_8())

	if header & HEADER_FLAGS.HAS_INPUT_BUTTON:
		var button_map := {}

		var button_val = buffer.get_u8()

		if button_val & BUTTON_FLAGS.P:
			button_map["p"] = true
		if button_val & BUTTON_FLAGS.K:
			button_map["k"] = true
		if button_val & BUTTON_FLAGS.A:
			button_map["a"] = true

		input["input_button"] = button_map

	all_input[path] = input
	return all_input
