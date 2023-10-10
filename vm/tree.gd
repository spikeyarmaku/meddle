extends Node2D

enum TermType {Fork, Leaf, Symbol, String, Rational}

const _side_length : float = 50
const _v_separation : float = 10
const _h_separation : float = 20

var TreeNode = load("res://vm/tree.tscn")
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

func _create_circle(radius : float):
    var poly = Polygon2D.new()
    var sides = 32
    var turn_step = TAU / sides
    var points = []
    for i in range(sides):
        var turn = i * turn_step
        points.append(Vector2(sin(turn), cos(turn)) * radius)
    poly.polygon = points
    return poly

func _create_shape():
    $Shape.add_child(_create_circle(20))
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
#    var shape_width = $SubTrees.get_child_count() * _side_length
    var line_start_x = position.x
#    var line_start_x = position.x - shape_width / 2 + \
#        child_count * _side_length + _side_length / 2
#    var line_end_x = $SubTrees.get_child(child_count).position.x
#    var line_start_y = _side_length / 2
#    var line_mid_y = line_start_y + _h_separation / 2
#    var line_end_y = line_start_y + _h_separation
#    line.points = \
#        [Vector2(line_start_x, line_start_y),
#        Vector2(line_start_x, line_mid_y),
#        Vector2(line_end_x, line_mid_y),
#        Vector2(line_end_x, line_end_y)]
    line.points = [Vector2(line_start_x, 0), $SubTrees.get_child(child_count).position]
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

func add_child_tree(tree):
    $SubTrees.add_child(tree)

func _construct_tree(serializer : Serializer):
    width = 1
    var type = serializer.read_uint8()
    match type:
        TermType.Fork:
            _construct_tree(serializer)
            var child = TreeNode.instantiate()
            child.construct_from_bytes(serializer)
            if $SubTrees.get_child_count() == 0:
                width = 0
            $SubTrees.add_child(child)
            width += child.width
        TermType.Leaf:
            pass
        TermType.Symbol:
            $Shape/Label.text = serializer.read_null_terminated_string()
        TermType.String:
            $Shape/Label.text = "\"" + serializer.read_null_terminated_string() + "\""
        TermType.Rational:
            $Shape/Label.text = _read_rational(serializer)

func construct_from_bytes(serializer : Serializer):
    _construct_tree(serializer)
    for i in range($SubTrees.get_child_count()):
        $SubTrees.get_child(i).position = _child_position(i)
    _create_shape()
