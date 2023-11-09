extends VBoxContainer

signal request_next_step()
signal display(index)

var _is_waiting : bool = false

var is_finished : bool = false:
    set(new_value):
        is_finished = new_value
        %ButtonStep.disabled = is_finished
        _run_mode = _run_mode and \
            (not is_finished && _current_step == _max_step)

var _max_step : int:
    get:
        return %HSliderStep.max_value
    set(value):
        %HSliderStep.max_value = value
var _current_step : int:
    get:
        return %HSliderStep.value
    set(new_value):
        if new_value > _max_step:
            if is_finished == false:
                request_next_step.emit()
                _is_waiting = true
            else:
                _run_mode = false
        else:
            %HSliderStep.value = new_value
            _update_buttons()
        display.emit(_current_step)

var _run_mode : bool = false:
    get:
        return _run_mode
    set(new_value):
        _run_mode = new_value
        if new_value == true:
            %ButtonRun.text = "Pause"
        else:
            %ButtonRun.text = "Run"

func _update_buttons():
    %ButtonBack.disabled = _current_step <= 0
    var stop : bool = is_finished && _current_step == _max_step
    %ButtonForward.disabled = stop
    %ButtonRun.disabled = stop
    _run_mode = _run_mode and not stop
    %ButtonStep.text = "STEP " + str(_current_step)

func _process(_delta):
    if _run_mode == true and not _is_waiting:
        _go_forward()

func reset():
    _is_waiting = false
    is_finished = false

    _current_step = -1
    _run_mode = false
    %HSliderStep.value = 0
    %SliderStep.editabel = false
    _max_step = 0

func new_state():
    _is_waiting = false
    if %HSliderStep.editable:
        _max_step += 1
    else:
        %HSliderStep.editable = true
    %HSliderStep.value = %HSliderStep.max_value

func _go_forward():
    _current_step += 1

func _go_back():
    _current_step -= 1

func _on_button_back_pressed():
    _go_back()

func _on_button_forward_pressed():
    _go_forward()

func _on_button_step_pressed():
    request_next_step.emit()

func _on_h_slider_step_drag_ended(_value_changed : bool):
    _current_step = %HSliderStep.value
    _run_mode = false

func _on_button_run_pressed():
    _run_mode = not _run_mode
    _go_forward()
