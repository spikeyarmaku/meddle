extends Control

signal highlight_frame(frame_index : int, to_highlight : bool)
signal jump_to_frame(frame_index : int)

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
    var count : int = serializer.read_word()
    for n in range(count):
        var closure := Closure.instantiate()
        closure.deserialize(serializer)
        closure.connect("highlight_frame",
            func(frame_index, to_highlight):
                emit_signal("highlight_frame", frame_index, to_highlight))
        closure.connect("jump_to_frame",
            func(frame_index): emit_signal("jump_to_frame", frame_index))
        %StackElems.add_child(closure)
        # Keep stack order
        %StackElems.move_child(closure, 0)

func reset():
    for c in %StackElems.get_children():
        c.queue_free()
