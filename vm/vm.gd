extends VBoxContainer

signal send_text(text : String)

var _vm_history : Array = []

var _max_step : int:
    get:
        return _vm_history.size()

var is_finished : bool:
    get:
        return $VMControl.is_finished
    set(value):
        $VMControl.is_finished = value

func reset():
    _vm_history.clear()
    $VMControl.max_step = _max_step
    $VMDisplay.reset()
    $VMControl.reset()

func new_state(bytes : PackedByteArray):
    if (bytes.size() != 0):
        _vm_history.append(bytes)
        print(bytes)
    $VMControl.max_step = _max_step
    $VMControl.new_state()

func _on_vm_control_request_next_step() -> void:
    send_text.emit("step")
    send_text.emit("get")

func _on_vm_control_display(index) -> void:
    $VMDisplay.reset()
    $VMDisplay.display(_vm_history[index])
