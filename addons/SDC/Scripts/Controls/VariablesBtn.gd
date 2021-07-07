tool
extends PopupBtn

var _var: String

func _ready():
	if (placeholder == ""):
		placeholder = "none_var"

func update_popup_list():
	
	if (AppInstance.resource != null):
		for item in AppInstance.resource.Variables:
			get_popup().add_item(item["Key"])
			
	for item in AppInstance.config["Variables"]:
		get_popup().add_item(item["Key"])


func selected_item(id: int):
	.selected_item(id)
	_var = get_popup().get_item_text(id) # AppInstance.config["Variables"][id - 1]
