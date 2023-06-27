#class_name Closure

extends Control

const bg_color_base : Color = Color("1d2229")
const bg_color_selection : Color = Color("2a291d")

const Term = preload("res://vm/templates/term.tscn")
var frame_index : int

var is_highlighted:
	get:
		return is_highlighted
	set(value):
		is_highlighted = value
		var stylebox : StyleBoxFlat = get_theme_stylebox("panel")
		if value:
			stylebox.bg_color = bg_color_selection
		else:
			stylebox.bg_color = bg_color_base

func deserialize(serializer : Serializer):
	var type : int = serializer.read_uint8()
	if type == 0:
		return
	if type == 2:
		var term = Term.instantiate()
		term.deserialize(serializer)
		%TermContainer.add_child(term)
	frame_index = serializer.read_word()

func reset():
	for c in %TermContainer.get_children():
		c.queue_free()

func set_expand(do_expand : bool):
	if do_expand:
		size_flags_horizontal = \
			(Control.SIZE_EXPAND | Control.SIZE_FILL) as Control.SizeFlags
	else:
		size_flags_horizontal = Control.SIZE_FILL
