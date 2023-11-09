extends VBoxContainer

signal send_text(text : String)

var is_finished : bool:
    get:
        return $VMControl.is_finished
    set(value):
        $VMControl.is_finished = value

func reset():
    $VMDisplay.reset()
    $VMControl.reset()

func new_state(bytes : PackedByteArray):
    $VMDisplay.new_state(bytes)
    $VMControl.new_state()

func _on_vm_control_request_next_step() -> void:
    send_text.emit("step")
    send_text.emit("get")

func _on_vm_control_display(index) -> void:
    $VMDisplay.display(index)
