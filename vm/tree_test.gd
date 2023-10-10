extends Node2D

const _TreeNode = preload("res://vm/tree.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var bytes = PackedByteArray([8, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1,
0, 0, 1, 0, 1, 1, 0, 1, 1])
    var tree = _TreeNode.instantiate()
    var ser = Serializer.new()
    ser.from_bytes(bytes)
    ser.read_word_size()
    tree.construct_from_bytes(ser)
    add_child(tree)

