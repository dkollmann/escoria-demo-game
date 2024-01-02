extends Popup

signal savegame_name_ok(savegame_name)
signal savegame_cancel

func _on_cancel_pressed():
	savegame_cancel.emit()
	hide()

func _on_ok_pressed():
	if not $MarginContainer/VBoxContainer/LineEdit.text.is_empty():
		savegame_name_ok.emit($MarginContainer/VBoxContainer/LineEdit.text)
		$MarginContainer/VBoxContainer/LineEdit.clear()
		hide()
