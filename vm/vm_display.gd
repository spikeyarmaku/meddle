extends Control

const Closure = preload("res://vm/templates/closure.tscn")
const TreeNode = preload("res://vm/tree.tscn")

var _dragging : bool = false

func _ready():
    _add_control_button()

func deserialize(serializer : Serializer):
    # Deserialize control
    %Control.program_deserialize(serializer)
    # Deserialize stack elements
    var stack_count = serializer.read_word()
    for i in range(stack_count):
        var is_parent = serializer.read_uint8()
        var tree_node = TreeNode.instantiate()
        tree_node.is_parent = is_parent
        tree_node.tree_deserialize(serializer)
        %Stack.add_child(tree_node)
        _add_stack_button()
        tree_node.visible = false

func reset():
    %Control.reset()
    for c in %Stack.get_children():
        c.queue_free()
        %Stack.remove_child(c)
    for c in %StackButtons.get_children():
        c.queue_free()
        %StackButtons.remove_child(c)
    _add_control_button()

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

func display(bytes):
    var serializer := Serializer.new()
    serializer.from_bytes(bytes)
    serializer.read_word_size()
    deserialize(serializer)

func _add_control_button():
    var button = Button.new()
    button.text = "Control"
    %StackButtons.add_child(button)
    button.pressed.connect(_on_stack_button_pressed.bind(-1))

func _add_stack_button():
    var button = Button.new()
    var index = %Stack.get_child_count()
    button.text = "STACK " + str(index)
    %StackButtons.add_child(button)
    button.pressed.connect(_on_stack_button_pressed.bind(index))

func _on_stack_button_pressed(index):
    print("PRESSED ", index)
    if index == 0:
        %Control.visible = true
        for c in %Stack.get_children():
            c.visible = false
    else:
        %Control.visible = true
        for c in %Stack.get_children():
            c.visible = false
        %Stack.get_child(index - 1).visible = true
