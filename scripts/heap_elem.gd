extends VBoxContainer

func set_binding_name(binding_name : String):
	$Header/Label.text = binding_name
	
func set_binding_closure(closure):
	$Header.add_child(closure)

func add_child_elem(elem):
	$HBoxContainer.add_child(elem)
