extends Node2D

enum ProgramType {Leaf, Stem, Fork}

var node_count : int = 1

var is_parent : bool = false

const _v_separation : float = 10
const _h_separation : float = 20
#const _spread_speed : float = 1000

var TreeNode = load("res://vm/tree.tscn")

var label:
    get:
        return %ExpandedLabel.text
    set(new_value):
        %ExpandedLabel.text = new_value
        %FoldedLabel.text = "(" + new_value + ")"

var _children_width = 0:
    get:
        var ch_width = 0
        for c in $SubTrees.get_children():
            ch_width += c.width
        ch_width += _h_separation * ($SubTrees.get_child_count() - 1)
        return ch_width
var width : int = 0:
    get:
        var own = $Node.size.x
        if _expanded:
            return max(own, _children_width)
        else:
            return own
    set(new_width):
        print("PANIC! Attempted to change width to ", new_width)

var _expanded : bool = true:
    get:
        return _expanded
    set(is_expanded):
        if $SubTrees.get_child_count() > 0:
            $SubTrees.visible = is_expanded
            $Shape.visible = is_expanded
            %ExpandedLabel.visible = is_expanded
            %FoldedLabel.visible = not is_expanded
            _expanded = is_expanded

func _process(_delta):
    if _expanded:
        for i in $SubTrees.get_child_count():
            var c = $SubTrees.get_child(i)
            var target_position = _child_position(i)
            var diff = target_position - c.position
            if diff.length_squared() > 10:
                c.position += diff / 2
                var l = $Shape.get_child(i)
                if l != null:
                    l.points[-1].x = c.position.x
                    l.points[-2].x = c.position.x

func _child_position(child_count : int) -> Vector2:
    var pos_x = -_children_width / 2.0
    for i in range(0, child_count):
        pos_x += $SubTrees.get_child(i).width + _v_separation
    pos_x += $SubTrees.get_child(child_count).width / 2.0
    return Vector2(pos_x, $Node.size.y + _h_separation)

func _line_to_child(child_count : int):
    var line = Line2D.new()
#    var line_start_x = position.x
    var line_end_x = $SubTrees.get_child(child_count).position.x
    var line_end_y = $SubTrees.get_child(child_count).position.y
    line.points = \
        [Vector2(0, 0),
        Vector2(0, line_end_y / 2),
        Vector2(line_end_x, line_end_y / 2),
        $SubTrees.get_child(child_count).position]
    return line

func _read_rational(serializer : Serializer) -> float:
    var rational_sign : int = serializer.read_uint8()
    if rational_sign == 2:
        rational_sign = -1
    var numerator = _read_alnat(serializer)
    var denominator = _read_alnat(serializer)
    return float(rational_sign) * numerator / denominator

# TODO make it handle arbitrarily large numbers
func _read_alnat(serializer : Serializer) -> int:
    var num : int = 0
    var power : int = 1
    var byte : int = serializer.read_uint8()
    while byte > 127:
        num += power * (byte - 128)
        power *= 128
        byte = serializer.read_uint8()
    num += power * byte
    return num

#func add_child_tree(tree):
#    $SubTrees.add_child(tree)

func set_expand(expand : bool, recursive : bool, node_limit : int):
    if expand == false:
        _expanded = false
        if recursive:
            for c in $SubTrees.get_children():
                c.set_expand(false, recursive, node_limit)
    else:
        if node_limit == 0 or node_count < node_limit:
            _expanded = true
            if recursive:
                for c in $SubTrees.get_children():
                    c.set_expand(expand, recursive, node_limit)
        else:
            _expanded = false
            if recursive:
                for c in $SubTrees.get_children():
                    c.set_expand(false, recursive, node_limit)

func program_deserialize(serializer : Serializer):
    label = serializer.read_null_terminated_string()
    if label == "":
        label = "Δ"
    var type = serializer.read_uint8()
    for i in type:
        var child = TreeNode.instantiate()
        child.program_deserialize(serializer)
        node_count += child.node_count
        $SubTrees.add_child(child)

func tree_deserialize_compact(serializer : Serializer):
    var type = serializer.read_uint8()
    match type:
        0:
            program_deserialize(serializer)
        1:
            var node = TreeNode.instantiate()
            tree_deserialize_compact(serializer)
            node.tree_deserialize_compact(serializer)
            node_count += node.node_count
            $SubTrees.add_child(node)

func tree_deserialize(serializer: Serializer):
    var type = serializer.read_uint8()
    match type:
        0:
            program_deserialize(serializer)
        1:
            var node0 = TreeNode.instantiate()
            var node1 = TreeNode.instantiate()
            node0.tree_deserialize(serializer)
            node1.tree_deserialize(serializer)
            node_count += node0.node_count + node1.node_count
            $SubTrees.add_child(node0)
            $SubTrees.add_child(node1)

func move_children(is_recursive : bool):
    # Change color if node has more than 2 children
    if $SubTrees.get_child_count() > 2:
        var stylebox = $Node.get_theme_stylebox("panel").duplicate()
        stylebox.bg_color = Color.LIGHT_CORAL
        $Node.add_theme_stylebox_override("panel", stylebox)
    for i in range($SubTrees.get_child_count()):
        $SubTrees.get_child(i).position = _child_position(i)
        $Shape.add_child(_line_to_child(i))
    if is_recursive:
        for c in $SubTrees.get_children():
            c.move_children(true)

func reset():
    label = ""
#    width = $Node.size.x
    for s in $Shape.get_children():
        s.queue_free()
        $Shape.remove_child(s)
    for c in $SubTrees.get_children():
        c.queue_free()
        $SubTrees.remove_child(c)

func _expand_all(is_expanded : bool):
    for c in $SubTrees.get_children():
        c._expanded = is_expanded
        c._expand_all(is_expanded)

func _on_node_gui_input(event: InputEvent) -> void:
    if event.is_action_pressed("fold_toggle", false, true):
        _expanded = not _expanded
    elif event.is_action_pressed("fold_toggle_all", false, true):
        _expand_all(not _expanded)
        _expanded = not _expanded
