tool
extends PopupBtn

var _content: Dictionary

func _ready():
	if (placeholder == ""):
		placeholder = "char_phrase"

func update_popup_list():
	for item in AppInstance.config["characters"]:
		get_popup().add_item(item["name"])

func selected_item(id: int):
	if (placeholder == ""):
		_content = AppInstance.config["characters"][id]
	elif (id > 0):
		_content = AppInstance.config["characters"][id - 1]
	else:
		_content = {}

	.selected_item(id)

func get_id() -> String:
	if (_content.empty()):
		return ""
	return _content["id"]

func get_name() -> String:
	if (_content.empty()):
		return ""
	return _content["name"]

func update_content(content):
	_content = content
	if !_content.empty():
		.set_text(content["name"])
	else:
		.set_text("char_phrase")
