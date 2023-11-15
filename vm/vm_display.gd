extends Control

const Closure = preload("res://vm/templates/closure.tscn")
const TreeNode = preload("res://vm/tree.tscn")

var _dragging : bool = false
var _stack_history = []

func new_state(bytes):
    # Create two serializers
    var serializer0 := Serializer.new()
    serializer0.from_bytes(bytes)
    serializer0.read_word_size()
    var serializer1 := Serializer.new()
    serializer1.from_bytes(bytes.duplicate())
    serializer1.read_word_size()
    # Serialize the stack
    var step = deserialize(serializer0)
    # Serialize the whole tree, add it a the last element
    step.add_child(_read_whole_tree(serializer1))
    # Add the step to the history
    _stack_history.append(step)
    # Display the current step
    display(_stack_history.size() - 1)

func deserialize(serializer : Serializer) -> Node2D:
    var step = Node2D.new()
    # Deserialize control
    var control = TreeNode.instantiate()
    control.visible = false
    control.program_deserialize(serializer)
    control.move_children(true)
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
        tree_node.move_children(true)
    return step

func _read_whole_tree(serializer):
    var whole_tree = TreeNode.instantiate()
    whole_tree.program_deserialize(serializer)
    var stack_count = serializer.read_word()
    var stack = []
    for i in range(stack_count):
        var is_parent = serializer.read_uint8()
        var tree_node = TreeNode.instantiate()
        tree_node.is_parent = is_parent
        tree_node.tree_deserialize_compact(serializer)
        tree_node.set_expand(true, 0)
        stack.append(tree_node)
    stack.reverse()
    for s in stack:
        if s.is_parent:
            s.get_node("SubTrees").add_child(whole_tree)
            whole_tree = s
        else:
            whole_tree.get_node("SubTrees").add_child(s)
    whole_tree.move_children(true)
    whole_tree.visible = true
    whole_tree.set_expand(true, 0)
    return whole_tree

func reset():
    for c in _stack_history:
        c.queue_free()
    %TreeHistoryContainer.remove_child(%TreeHistoryContainer.get_child(0))

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
    %TreeHistoryContainer.remove_child(%TreeHistoryContainer.get_child(0))
    %TreeHistoryContainer.add_child(_stack_history[index])
    _update_side_buttons(index)

func _update_side_buttons(history_index : int):
    # Clear the side buttons
    for c in %StackButtons.get_children():
        c.queue_free()
        %StackButtons.remove_child(c)
    # Query the current step
    var step = _stack_history[history_index]
    # Create the button that shows the whole tree
    var tree_button = Button.new()
    tree_button.toggle_mode = true
    tree_button.text = "Tree"
    %StackButtons.add_child(tree_button)
    tree_button.pressed.connect(_on_tree_button_pressed.bind(history_index, tree_button))
    tree_button.button_pressed = step.get_child(step.get_child_count() - 1).visible
    %StackButtons.add_child(HSeparator.new())
    # Create buttons for the control and the stack elements
    for stack_index in step.get_child_count() - 1:
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
            _on_stack_button_pressed.bind(history_index, stack_index, button))

func _on_stack_button_pressed(history_index, stack_index, button):
    for c in %StackButtons.get_children():
        if c is Button:
            c.button_pressed = c == button
    var step = _stack_history[history_index]
    for i in step.get_child_count():
        step.get_child(i).visible = i == stack_index

func _on_tree_button_pressed(history_index, tree_button):
    for c in %StackButtons.get_children():
        if c is Button:
            c.button_pressed = c == tree_button
    var step = _stack_history[history_index]
    for i in step.get_child_count():
        step.get_child(i).visible = i == step.get_child_count() - 1
