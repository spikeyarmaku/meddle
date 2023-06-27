#class_name PrimVal

extends Label

const string_color : Color = Color("ffeda0ff")
const rational_color : Color = Color("a0ffe0ff")
const symbol_color : Color = Color("cdced2ff")

enum PrimValType {RationalValue, StringValue, SymbolValue}

var type : PrimValType:
	get: return type
	set(new_value):
		type = new_value
		match type:
			PrimValType.RationalValue:
				add_theme_color_override("font_color", rational_color)
			PrimValType.StringValue:
				add_theme_color_override("font_color", string_color)
			PrimValType.SymbolValue:
				add_theme_color_override("font_color", symbol_color)

func deserialize(serializer : Serializer):
	type = serializer.read_uint8() as PrimValType
	match type:
		0: text = str(_read_rational(serializer))
		1, 2: text = serializer.read_null_terminated_string()

func _read_rational(serializer : Serializer) -> float:
	var rational_sign : int = serializer.read_uint8()
	if rational_sign == 2:
		rational_sign = -1
	var numerator = _read_alnat(serializer)
	var denominator = _read_alnat(serializer)
	return float(rational_sign) * numerator / denominator
	
# TODO make it handle arbitrarily large numbers
func _read_alnat(serializer : Serializer) -> int:
	var num : int = 0
	var power : int = 1
	var byte : int = serializer.read_uint8()
	while byte > 127:
		num += power * (byte - 128)
		power *= 128
		byte = serializer.read_uint8()
	num += power * byte
	return num
