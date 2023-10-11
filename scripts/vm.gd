extends Control

signal send_text(text : String)

var is_finished : bool = false:
    set(new_value):
        is_finished = new_value
        %ButtonStep.disabled = is_finished
        _run_mode = _run_mode and \
            (not is_finished && _current_step == _max_step)

var _vm_history : Array = []
var _max_step : int:
    get:
        return _vm_history.size() - 1
var _current_step : int:
    get:
        return %HSliderStep.value
    set(new_value):
        if new_value > _max_step:
            if is_finished == false:
                _request_next_step()
            else:
                _run_mode = false
        elif new_value >= 0:
            %HSliderStep.value = new_value
            %ButtonBack.disabled = _current_step <= 0
            var stop : bool = is_finished && _current_step == _max_step
            %ButtonForward.disabled = stop
            %ButtonRun.disabled = stop
            _run_mode = _run_mode and not stop
            %ButtonStep.text = "STEP " + str(_current_step)
            _refresh_current_state()
var _run_mode : bool = false:
    get:
        return _run_mode
    set(new_value):
        _run_mode = new_value
        if new_value == true:
            %ButtonRun.text = "Pause"
        else:
            %ButtonRun.text = "Run"

func _process(_delta):
    if _run_mode == true:
        _go_forward()

func reset():
    %TreeContainer.reset()

func new_state(bytes : PackedByteArray):
    if (bytes.size() != 0):
        _vm_history.append(bytes)
        print(bytes)
    %HSliderStep.max_value = _max_step
#    if _run_mode == true:
    _go_forward()

func _deserialize(serializer : Serializer):
    serializer.read_word_size()
    %TreeContainer.deserialize(serializer)

func _refresh_current_state() -> void:
    reset()
    var serializer := Serializer.new()
    serializer.from_bytes(_vm_history[_current_step])
    _deserialize(serializer)

func _request_next_step():
    emit_signal("send_text", "step")
    emit_signal("send_text", "get")

func _go_forward():
    _current_step += 1

func _go_back():
    %HSliderStep.min_value = 0
    _current_step -= 1

func _on_repl_text_submitted(text : String):
    emit_signal("send_text", text)

func _on_button_back_pressed():
    _go_back()

func _on_button_forward_pressed():
    _go_forward()

func _on_button_step_pressed():
    _request_next_step()

func _on_h_slider_step_drag_ended(_value_changed : bool):
    _current_step = %HSliderStep.value
    _run_mode = false

func _on_button_run_pressed():
    _run_mode = not _run_mode
    _go_forward()
