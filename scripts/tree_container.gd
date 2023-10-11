extends Control

const Closure = preload("res://vm/templates/closure.tscn")

func deserialize(serializer : Serializer):
    %Tree.deserialize(serializer)

func reset():
    %Tree.reset()
