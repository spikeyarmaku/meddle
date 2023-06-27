extends Control

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
	var closure := Closure.instantiate()
	closure.deserialize(serializer)
	%ClosureContainer.add_child(closure)

func reset():
	for c in %ClosureContainer.get_children():
		c.queue_free()
