extends Control

signal send_text(text : String)

func get_vm():
    return %VM

func _on_repl_text_submitted(text : String):
    send_text.emit(text)

func _on_vm_send_text(text) -> void:
    send_text.emit(text)
