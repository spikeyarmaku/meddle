extends VBoxContainer

func set_binding_name(frame_index : int, binding_name : String):
    $Header/LabelFrameIndex.text = str(frame_index)
    $Header/LabelBindingName.text = binding_name

func set_binding_closure(closure):
    $Header/ClosureContainer.add_child(closure)

func get_binding_closure():
    return $Header/ClosureContainer.get_child(0)

func add_child_elem(elem):
    $HBoxContainer.add_child(elem)
