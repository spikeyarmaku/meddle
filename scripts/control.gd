extends Control

signal highlight_frame(frame_index : int, to_highlight : bool)

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
	var closure := Closure.instantiate()
	closure.deserialize(serializer)
	closure.connect("highlight_frame",
		func(frame_index, to_highlight):
			emit_signal("highlight_frame", frame_index, to_highlight))
	%ClosureContainer.add_child(closure)

func reset():
	for c in %ClosureContainer.get_children():
		c.queue_free()
