extends Control

const Closure = preload("res://vm/templates/closure.tscn")
const HeapElem = preload("res://vm/heap_elem.tscn")

var _elements : Array = [null]

func deserialize(serializer : Serializer):
	var count : int = serializer.read_word()
	for n in range(count):
		var name : String = serializer.read_null_terminated_string()
		var closure := Closure.instantiate()
		closure.deserialize(serializer)
		closure.set_expand(true)
		var heap_elem = HeapElem.instantiate()
		heap_elem.set_binding_name(name)
		heap_elem.set_binding_closure(closure)
		_elements.append(heap_elem)
		var parent_index : int = serializer.read_word()
		if _elements[parent_index] == null:
			%PanelContainer.add_child(heap_elem)
		else:
			_elements[parent_index].add_child_elem(heap_elem)

func reset():
	for c in %PanelContainer.get_children():
		c.queue_free()
	_elements = [null]
