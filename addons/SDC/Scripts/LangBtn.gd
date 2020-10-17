tool
extends PopupBtn

var _var: String
func _ready():
	if (placeholder == ""):
		placeholder = "lang"


func update_popup_list():
	get_popup().add_item("ru")
	get_popup().add_item("en")
	
func selected_item(id: int):
	.selected_item(id)
	TranslationServer.set_locale(get_popup().get_item_text(id))
	AppInstance.change_setting("locale", get_popup().get_item_text(id))
#	 get_popup().get_item_text(id) # AppInstance.config["variables"][id - 1]
