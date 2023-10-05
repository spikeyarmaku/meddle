extends Node2D

const _TreeNode = preload("res://vm/tree.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var bytes = PackedByteArray([3, 1, 2, 0, 2, 0, 2, 1, 0, 1, 0, 1, 0, 2, 0, 2, 1, 0, 1, 0])
    var tree = _TreeNode.instantiate()
    tree.construct_from_bytes(bytes)
    add_child(tree)

