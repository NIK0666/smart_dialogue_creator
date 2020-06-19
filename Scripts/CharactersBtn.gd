extends PopupBtn

var _content: Dictionary

func _ready():
	if (placeholder == ""):
		placeholder = "[None char]"
	._ready()

func update_popup_list():
	for item in AppInstance.config["characters"]:
		get_popup().add_item(item["name"])

func selected_item(id: int):
	_content = AppInstance.config["characters"][id - 1]
	.selected_item(id)
