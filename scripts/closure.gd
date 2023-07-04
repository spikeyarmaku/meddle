#class_name Closure

extends Control

signal highlight_frame(frame_index : int, to_highlight : bool)
signal jump_to_frame(frame_index : int)

const bg_color_base : Color = Color("1d2229")
const bg_color_selection : Color = Color("2a291d")
const bg_color_mark : Color = Color("fff279")

const Term = preload("res://vm/templates/term.tscn")
var frame_index : int

func _ready():
	$HBoxContainer/FrameMarker/Label.text = str(frame_index)

var is_highlighted: bool = false:
	get:
		return is_highlighted
	set(value):
		is_highlighted = value
		if value:
			_set_stylebox_color(bg_color_selection)
		else:
			_set_stylebox_color(bg_color_base)

func _set_stylebox_color(color : Color):
	var stylebox : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = color
	add_theme_stylebox_override("panel", stylebox)

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

func blink():
	var tween : Tween = create_tween().set_loops(5).set_trans(Tween.TRANS_SINE)
	tween.tween_method(_set_stylebox_color, bg_color_base, bg_color_mark, 0.1)\
		.set_ease(Tween.EASE_IN)
	tween.tween_method(_set_stylebox_color, bg_color_mark, bg_color_base, 0.1)\
		.set_ease(Tween.EASE_OUT)

func get_term():
	if %TermContainer.get_child_count() > 0:
		return %TermContainer.get_child(0)
	else:
		return null

func _on_frame_marker_mouse_entered():
	is_highlighted = true
	emit_signal("highlight_frame", frame_index, true)

func _on_frame_marker_mouse_exited():
	is_highlighted = false
	emit_signal("highlight_frame", frame_index, false)

func _on_frame_marker_gui_input(event):
	if event is InputEventMouseButton and event.pressed and \
			event.button_index == 1:
		emit_signal("jump_to_frame", frame_index)
