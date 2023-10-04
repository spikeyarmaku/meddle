extends VBoxContainer

signal text_submitted(text : String)

func _on_line_edit_text_submitted(new_text):
    emit_signal("text_submitted", new_text)
    $LineEdit.text = ""
