tool
extends PopupBtn

var _content: Dictionary

func _ready():
	if (placeholder == ""):
		placeholder = "char_phrase"

func update_popup_list():
	for item in AppInstance.config["Characters"]:
		get_popup().add_item(item["Name"])

func selected_item(id: int):
	if (placeholder == ""):
		_content = AppInstance.config["Characters"][id]
	elif (id > 0):
		_content = AppInstance.config["Characters"][id - 1]
	else:
		_content = {}

	.selected_item(id)

func get_id() -> String:
	if (_content.empty()):
		return ""
	return _content["Id"]

func get_name() -> String:
	if (_content.empty()):
		return ""
	return _content["Name"]

func update_content(content):
	_content = content
	if !_content.empty():
		.set_text(content["Name"])
	else:
		.set_text("char_phrase")
