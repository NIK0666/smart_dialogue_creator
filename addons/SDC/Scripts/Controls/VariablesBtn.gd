tool
extends PopupBtn

var _var: String

func _ready():
	if (placeholder == ""):
		placeholder = "none_var"

func update_popup_list():
	
	if (AppInstance.resource != null):
		for item in AppInstance.resource.variables:
			get_popup().add_item(item["key"])
			
	for item in AppInstance.config["variables"]:
		get_popup().add_item(item["key"])


func selected_item(id: int):
	.selected_item(id)
	_var = get_popup().get_item_text(id) # AppInstance.config["variables"][id - 1]
