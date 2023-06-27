extends Control

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
	var count : int = serializer.read_word()
	for n in range(count):
		var closure := Closure.instantiate()
		closure.deserialize(serializer)
		%StackElems.add_child(closure)
		# Keep stack order
		%StackElems.move_child(closure, 0)

func reset():
	for c in %StackElems.get_children():
		c.queue_free()
