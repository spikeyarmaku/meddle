extends Control

signal highlight_frame(frame_index : int, to_highlight : bool)
signal jump_to_frame(frame_index : int)

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
    var closure := Closure.instantiate()
    closure.deserialize(serializer)
    closure.connect("highlight_frame",
        func(frame_index, to_highlight):
            emit_signal("highlight_frame", frame_index, to_highlight))
    closure.connect("jump_to_frame",
            func(frame_index): emit_signal("jump_to_frame", frame_index))
    %ClosureContainer.add_child(closure)

func reset():
    for c in %ClosureContainer.get_children():
        c.queue_free()
