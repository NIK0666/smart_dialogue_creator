tool
extends Tabs

export var hint_id: String = ""
export var text_id: String = ""

func _ready():
	if (!hint_id.empty()):
		hint_tooltip = AppInstance.get_local_text(hint_id)
	if (!text_id.empty()):
		get_parent().set_tab_title(get_index(), AppInstance.get_local_text(text_id))
