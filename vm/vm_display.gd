extends Control

const Closure = preload("res://vm/templates/closure.tscn")
const TreeNode = preload("res://vm/tree.tscn")

var _dragging : bool = false

func new_state(bytes):
    var serializer := Serializer.new()
    serializer.from_bytes(bytes)
    serializer.read_word_size()
    %TreeHistoryContainer.add_child(deserialize(serializer))
    display(%TreeHistoryContainer.get_child_count() - 1)

func deserialize(serializer : Serializer) -> Node2D:
    var step = Node2D.new()
    # Deserialize control
    var control = TreeNode.instantiate()
    control.program_deserialize(serializer)
    step.add_child(control)
    # Deserialize stack elements
    var stack_count = serializer.read_word()
    for i in range(stack_count):
        var is_parent = serializer.read_uint8()
        var tree_node = TreeNode.instantiate()
        tree_node.is_parent = is_parent
        tree_node.tree_deserialize(serializer)
        step.add_child(tree_node)
        tree_node.visible = false
    return step

func reset():
    for c in %TreeHistoryContainer.get_children():
        c.queue_free()
        %TreeHistoryContainer.remove_child(c)

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
    if event.is_action_pressed("camera_move"):
        _dragging = true
    elif event.is_action_released("camera_move"):
        _dragging = false
    elif event.is_action_pressed("camera_zoom_in"):
        %Camera2D.zoom *= 1.2
    elif event.is_action_pressed("camera_zoom_out"):
        %Camera2D.zoom /= 1.2

    if event is InputEventMouseMotion:
        if _dragging:
            %Camera2D.position -= event.relative / %Camera2D.zoom

func display(index : int):
    for i in %TreeHistoryContainer.get_child_count():
        %TreeHistoryContainer.get_child(i).visible = i == index
    _update_side_buttons(index)

func _update_side_buttons(history_index : int):
    for c in %StackButtons.get_children():
        c.queue_free()
        %StackButtons.remove_child(c)
    var step = %TreeHistoryContainer.get_child(history_index)
    for stack_index in step.get_child_count():
        var button = Button.new()
        button.toggle_mode = true
        var step_child = step.get_child(stack_index)
        button.button_pressed = step_child.visible
        if step_child.is_parent:
            button.text = "[P] "
        else:
            button.text = ""
        if stack_index == 0:
            button.text += "Control"
        else:
            button.text += "STACK " + str(stack_index)
        %StackButtons.add_child(button)
        button.pressed.connect(
            _on_stack_button_pressed.bind(history_index, stack_index))

func _on_stack_button_pressed(history_index, stack_index):
    for i in %StackButtons.get_child_count():
        %StackButtons.get_child(i).button_pressed = i == stack_index
    var step = %TreeHistoryContainer.get_child(history_index)
    for i in step.get_child_count():
        step.get_child(i).visible = i == stack_index
