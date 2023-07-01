extends Control

signal send_text(text : String)

#@export var minimum_tick_distance : float = 25

var _vm_history : Array = []
var _max_step : int:
	get:
		return _vm_history.size() - 1
var _current_step : int:
	get:
		return %HSliderStep.value
	set(new_value):
		if new_value >= 0 and new_value <= _max_step:
			%HSliderStep.value = new_value
			%ButtonBack.disabled = _current_step <= 0
			%ButtonForward.disabled = _current_step == _max_step
			%ButtonStep.text = "STEP " + str(_current_step)
			_refresh_current_state()

func _on_repl_text_submitted(text : String):
	emit_signal("send_text", text)

func reset():
	%Heap.reset()
	%Control.reset()
	%Stack.reset()

func new_state(bytes : PackedByteArray):
	_vm_history.append(bytes)
	%HSliderStep.max_value = _max_step
#	_adjust_slider_tick_count()
	_current_step = _max_step
#	_deserialize(serializer)

#func _adjust_slider_tick_count():
#	var divider : int = 5
#	var tick_count : int = _max_step
#	var tick_distance : float = %HSliderStep.size.x / tick_count
#	while tick_distance < minimum_tick_distance:
#		tick_count = floor(tick_count / divider)
#		tick_distance = %HSliderStep.size.x / tick_count
#		if divider == 5:
#			divider = 2
#		else:
#			divider = 5
#	%HSliderStep.tick_count = tick_count

func _deserialize(serializer : Serializer):
	serializer.read_word_size()
	%Heap.deserialize(serializer)
	%Control.deserialize(serializer)
	%Stack.deserialize(serializer)

func _refresh_current_state() -> void:
	reset()
	var serializer := Serializer.new()
	serializer.from_bytes(_vm_history[_current_step])
	_deserialize(serializer)

func _on_stack_highlight_frame(frame_index, to_highlight):
	%Heap.highlight_frame(frame_index, to_highlight)

func _on_control_highlight_frame(frame_index, to_highlight):
	%Heap.highlight_frame(frame_index, to_highlight)

func _on_button_back_pressed():
	_current_step -= 1

func _on_button_forward_pressed():
	_current_step += 1

func _on_button_step_pressed():
	emit_signal("send_text", "step")
#	await get_tree().create_timer(0.05).timeout
	emit_signal("send_text", "get")

func _on_h_slider_step_drag_ended(value_changed : bool):
	_current_step = %HSliderStep.value
