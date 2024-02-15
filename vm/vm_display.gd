extends Control

const Closure = preload("res://vm/templates/closure.tscn")
const TreeNode = preload("res://vm/tree.tscn")
const EXPAND_NODE_COUNT_LIMIT = 50

var _dragging : bool = false
var _stack_history = []

func new_state(bytes):
    # Create a serializer
    var serializer := Serializer.new()
    serializer.from_bytes(bytes)
    serializer.read_word_size()
    print("Word size: " + str(serializer._word_size))
    # Serialize the whole tree, add it as the last element
    var step = deserialize(serializer)
    # Add the step to the history
    _stack_history.append(step)
    # Display the current step
    display(_stack_history.size() - 1)

func deserialize(serializer : Serializer) -> Node2D:
    var step = Node2D.new()
    # Deserialize control
    var tree = TreeNode.instantiate()
    #tree.visible = false
    tree.tree_deserialize(serializer)
    tree.move_children(true)
    tree.set_expand(true, true, EXPAND_NODE_COUNT_LIMIT)
    step.add_child(tree)
    return step

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
    if %TreeHistoryContainer.get_child_count() > 0:
        %TreeHistoryContainer.remove_child(%TreeHistoryContainer.get_child(0))
    %TreeHistoryContainer.add_child(_stack_history[index])

func _on_stack_button_pressed(history_index, stack_index, button):
    for c in %StackButtons.get_children():
        if c is Button:
            c.button_pressed = c == button
    var step = _stack_history[history_index]
    for i in step.get_child_count():
        step.get_child(i).visible = i == stack_index
