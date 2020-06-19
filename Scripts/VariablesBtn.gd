extends PopupBtn

var _content: Dictionary

func _ready():
	if (placeholder == ""):
		placeholder = "[None var]"
	._ready()

func update_popup_list():
	for item in AppInstance.config["variables"]:
		get_popup().add_item(item["var"])

func selected_item(id: int):
	.selected_item(id)
	_content = AppInstance.config["variables"][id - 1]
