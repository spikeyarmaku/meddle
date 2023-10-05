extends Node2D

const _side_length : float = 50
const _v_separation : float = 10
const _h_separation : float = 30

var _TreeNode = load("res://vm/tree.tscn")
var width : int = 0

func _create_rect(side_length : float, slot_number : int):
    var poly = Polygon2D.new()
    if slot_number == 0:
        var p1 = Vector2(side_length / 2, side_length / 2)
        var p2 = Vector2(-p1.x, p1.y)
        var p3 = Vector2(0, -p1.y)
        poly.polygon = [p1, p2, p3]
    else:
        var p1 = Vector2(slot_number * side_length / 2, side_length / 2)
        var p2 = Vector2(-p1.x, p1.y)
        var p3 = Vector2(-p1.x, -p1.y)
        var p4 = Vector2(p1.x, -p1.y)
        poly.polygon = [p1, p2, p3, p4]
    return poly

func _create_shape(child_count : int):
    $Shape.add_child(_create_rect(_side_length, child_count))
    for i in range($SubTrees.get_child_count()):
        $Shape.add_child(_line_to_child(i))

func _real_width(w : int):
    return w * _side_length + (w - 1) * _v_separation

func _child_position(child_count : int) -> Vector2:
    var total_width = 0
    total_width += _real_width(width)
    var start_x = 0
    for i in range(0, child_count):
        start_x += \
            _real_width($SubTrees.get_child(i).width) + _v_separation
    start_x += _real_width($SubTrees.get_child(child_count).width) / 2
    return Vector2(position.x - total_width / 2 + start_x,
        position.y + _side_length + _h_separation)

func _line_to_child(child_count : int):
    var line = Line2D.new()
    var shape_width = $SubTrees.get_child_count() * _side_length
    var line_start_x = position.x - shape_width / 2 + \
        child_count * _side_length + _side_length / 2
    var line_end_x = $SubTrees.get_child(child_count).position.x
    var line_start_y = _side_length / 2
    var line_mid_y = line_start_y + _h_separation / 2
    var line_end_y = line_start_y + _h_separation
    line.points = \
        [Vector2(line_start_x, line_start_y),
        Vector2(line_start_x, line_mid_y),
        Vector2(line_end_x, line_mid_y),
        Vector2(line_end_x, line_end_y)]
    return line

func construct_from_bytes(bytes) -> int:
    var child_count = bytes[0]
    var counter = 1
    # call the children with bytes.slice(x)
    if child_count == 0:
        width = 1
    else:
        for i in range(0, child_count):
            var tree = _TreeNode.instantiate()
            counter += tree.construct_from_bytes(bytes.slice(counter))
            $SubTrees.add_child(tree)
            width += tree.width
        for i in range(0, child_count):
            $SubTrees.get_child(i).position = _child_position(i)
    _create_shape(child_count)
    return counter
