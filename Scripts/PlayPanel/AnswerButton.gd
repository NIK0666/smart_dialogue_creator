extends Button


signal select_answer(id)

func set_text(text: String):
	self.text = text
	self.hint_tooltip = text


func _on_Button_pressed():
	emit_signal("select_answer", get_index())
