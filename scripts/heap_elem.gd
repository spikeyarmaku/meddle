extends VBoxContainer

func set_binding_name(name : String):
	$Header/Label.text = name
	
func set_binding_closure(closure):
	$Header.add_child(closure)

func add_child_elem(elem):
	$HBoxContainer.add_child(elem)
