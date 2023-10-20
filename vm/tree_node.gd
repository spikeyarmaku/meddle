extends Polygon2D

# Constructing a tree:
# - Construct the children
# - Handle child collisions
# - Delete collisions for the children
# - Create one big collision, encompassing self and the children

enum TermType {Delta, Symbol, String, Rational, Primop}
enum Primop {Add, Sub, Mul, Div, Eq}

signal spread()
signal collision_done()

const _radius = 20 # Radius of a node's visible part
const _distance = 80 # distance between a node and one of its children's center
const _base_rot_step = PI/20 # rotation from one child to the next at the start

var depth = 0
var weight = 0
var _TreeNode = load("res://vm/tree_node.tscn")
var _collisions = []
var _spread = 0
var _spread_diff = 0.1
var _children_ready = 0

func reset():
    for c in $Children.get_children():
        c.queue_free()
        remove_child(c)

func deserialize(serializer : Serializer):
    _deserialize_node_type(serializer)
    _deserialize_children(serializer)

func get_collider():
    return $AvoidanceZone

func remove_collider():
    $AvoidanceZone.queue_free()

func get_collisions():
    return _collisions

# ------------------------------------------------------------------------------

func _ready():
    polygon = _create_circle(20)

func _physics_process(_delta):
#    $Label.text = str(_children_ready)
    if _children_ready == $Children.get_child_count():
        $Label.text = str(self)
#        print(self, " ", get_path())
        _handle_child_collisions()
    else:
        $Label.text = str(weight)

func _create_circle(radius : float) -> PackedVector2Array:
    var sides = 32
    var turn_step = TAU / sides
    var points = PackedVector2Array()
    for i in range(sides):
        var turn = i * turn_step
        points.append(Vector2(sin(turn), cos(turn)) * radius)
    return points

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

func _deserialize_node_type(serializer : Serializer):
    var type = serializer.read_uint8()
    match type:
        TermType.Delta:
            pass
        TermType.Symbol:
            $Label.text = serializer.read_null_terminated_string()
        TermType.String:
            $Label.text = "\"" + serializer.read_null_terminated_string() + "\""
        TermType.Rational:
            $Label.text = str(_read_rational(serializer))
        TermType.Primop:
            var primop = serializer.read_uint8()
            match primop:
                Primop.Add:
                    $Label.text = "<Add>"
                Primop.Sub:
                    $Label.text = "<Sub>"
                Primop.Mul:
                    $Label.text = "<Mul>"
                Primop.Div:
                    $Label.text = "<Div>"
                Primop.Eq:
                    $Label.text = "<Eq>"

func _deserialize_children(serializer : Serializer):
    var child_count = serializer.read_uint8()
    if child_count > 2:
        color = Color.ORANGE_RED
    for i in child_count:
        var edge = Line2D.new()
        edge.points = [Vector2.ZERO, Vector2(0, _distance)]
        var tree_node = _TreeNode.instantiate()
        $Children.add_child(edge)
        edge.add_child(tree_node)
        tree_node.depth = depth + 1
        tree_node.deserialize(serializer)
        weight = max(weight, tree_node.weight)
        tree_node.spread.connect(_handle_child_collisions)
        tree_node.collision_done.connect(_on_child_collision_done)
        tree_node.position = Vector2(0, _distance)
        _spread = _base_rot_step * child_count
        edge.rotation = _spread / 2 - (i + 0.5) * (_spread / child_count)
#        edge.rotation = (child_count - 1) * _base_rot_step / 2.0 - \
#            i * _base_rot_step
    weight += 1

func _on_avoidance_zone_area_entered(area: Area2D) -> void:
    _collisions.append(area)

func _on_avoidance_zone_area_exited(area: Area2D) -> void:
    _collisions.erase(area)

func _handle_child_collisions():
    # Adjust children until they don't collide with each other
    var children_collide = true
    var child_colliders = []
    var child_collisions = {}
    for e in $Children.get_children():
        var c = e.get_child(0)
        child_colliders.append(c.get_collider())
        for cc in c.get_collisions():
            child_collisions[cc] = true

    children_collide = false
    for c in child_colliders:
        if child_collisions.has(c):
            children_collide = true
            break
    if children_collide:
        _spread_children()
    else:
        # Create one all-encompassing collision
        _create_collision()
        collision_done.emit()
        _children_ready += 1

#func _spread_children():
#    var child_count = $Children.get_child_count()
#    for i in child_count:
#        var c = $Children.get_child(i)
#        _spread += 0.05
#        c.rotation = _spread / 2 - (i + 0.5) * (_spread / child_count)

# Calculate the weighed center of the rotation (weighed by depth)
func _spread_children():
    var child_count = $Children.get_child_count()
    if child_count == 1:
        return
    var middle : float = 0
    var total_weight : float = 0
    for i in child_count:
        var c = $Children.get_child(i).get_child(0)
        middle += i * c.weight
        total_weight += c.weight
    middle /= total_weight
    var middle_rot : float = lerp(_spread / 2, -_spread / 2, middle / float(child_count - 1))
    if depth == 5 and child_count == 3:
        print(total_weight, " ", middle, " ", middle_rot)
    if _spread + _spread_diff > 1.8 * PI:
        print("PANIC! _spread > PI")
        _spread_diff *= 0.9
        return
    _spread += _spread_diff
    for i in child_count:
        var c = $Children.get_child(i)
        c.rotation = _spread / 2 - i * (_spread / (child_count - 1)) - middle_rot

#func _create_collision():
#    var points = $AvoidanceZone/CollisionPolygon2D.polygon
#    # Collect children's collision polygons
#    for c in $Children.get_children():
#        var poly = c.get_child(0).get_collider()
#        var tf = poly.shape_owner_get_owner(poly.shape_find_owner(0)).global_transform
#        for p in poly.get_child(0).polygon:
#            points.append(p * tf.affine_inverse() * global_transform)
#        c.get_child(0).remove_collider()
#
#    $AvoidanceZone/CollisionPolygon2D.polygon = Geometry2D.convex_hull(points)

func _create_collision():
    # Collect children's collision polygons
    for c in $Children.get_children():
        var avoidance_zone = c.get_child(0).get_collider()
        for shape in avoidance_zone.get_children():
            var tf = shape.global_transform
            avoidance_zone.remove_child(shape)
            $AvoidanceZone.add_child(shape)
            shape.transform = global_transform.inverse() * tf

func _on_child_collision_done():
    _children_ready += 1
