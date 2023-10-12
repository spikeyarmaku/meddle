extends Control

var _dragging : bool = false

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
    %Tree.deserialize(serializer)

func reset():
    %Tree.reset()

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                _dragging = event.pressed
            MOUSE_BUTTON_WHEEL_UP:
                %Camera2D.zoom *= 1.2
            MOUSE_BUTTON_WHEEL_DOWN:
                %Camera2D.zoom /= 1.2
    elif event is InputEventMouseMotion:
        if _dragging:
            %Camera2D.position -= event.relative / %Camera2D.zoom
