tool
extends Button

class_name DialSimpleButton

export var hint_id: String = ""
export var text_id: String = ""

func _enter_tree():
	if (!hint_id.empty()):
		hint_tooltip = AppInstance.get_local_text(hint_id)
	if (!text_id.empty()):
		text = AppInstance.get_local_text(text_id)
