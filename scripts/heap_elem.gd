extends VBoxContainer

func set_binding_name(frame_index : int, binding_name : String):
	$Header/LabelFrameIndex.text = str(frame_index)
	$Header/LabelBindingName.text = binding_name
	
func set_binding_closure(closure):
	$Header.add_child(closure)

func add_child_elem(elem):
	$HBoxContainer.add_child(elem)
