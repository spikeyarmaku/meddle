extends Control

signal send_text(text : String)

# Called when the node enters the scene tree for the first time.
#func _ready():
#	%Repl.connect("text_submitted", _on_repl_text_submitted)

func _on_repl_text_submitted(text : String):
	emit_signal("send_text", text)

func reset():
	%Heap.reset()
	%Control.reset()
	%Stack.reset()

func deserialize(serializer : Serializer):
	serializer.read_word_size()
	%Heap.deserialize(serializer)
	%Control.deserialize(serializer)
	%Stack.deserialize(serializer)
