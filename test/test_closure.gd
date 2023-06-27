extends Control

# VM state after evaluating (+ 1 2)
var test_bytes = \
	[8, 0, 2, 2, 4, 2, 0, 0, 1, 1, 1, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0]
#	[8, 0, 0, 0, 1, 1, 1]
#	[ 8,  4,  0,  0,  0,  0,  0,  0,  0, 43,  0,  1,  4,  2,  0,  0,
#	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 45,  0,
#	  1,  4,  3,  1,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,
#	  0,  0,  0, 42,  0,  1,  4,  4,  2,  0,  0,  0,  0,  0,  0,  0,
#	  2,  0,  0,  0,  0,  0,  0,  0, 47,  0,  1,  4,  5,  3,  0,  0,
#	  0,  0,  0,  0,  0,  3,  0,  0,  0,  0,  0,  0,  0,  1,  2,  2,
#	  0,  2, 43,  0,  0,  0,  1,  1,  1,  0,  0,  1,  2,  1,  4,  0,
#	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]

# Called when the node enters the scene tree for the first time.
func _ready():
	var serializer := Serializer.new()
	serializer.from_bytes(test_bytes)
	$Closure.deserialize(serializer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
