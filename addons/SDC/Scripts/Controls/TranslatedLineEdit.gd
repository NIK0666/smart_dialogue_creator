tool
extends LineEdit


class_name DialTransLineEdit

export var hint_id: String = ""
export var placeholder_id: String = ""

func _enter_tree():
	if (!hint_id.empty()):
		hint_tooltip = AppInstance.get_local_text(hint_id)
	if (!placeholder_id.empty()):
		placeholder_text = AppInstance.get_local_text(placeholder_id)
