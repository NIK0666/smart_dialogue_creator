extends HBoxContainer

var _content: Dictionary
var _is_public: bool
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_content(content: Dictionary):
	_content = content
	$NameText.text = content["key"]
	$ValueText.text = content["value"]
	$DescText.text = content["desc"]

func _on_DelBtn_pressed():
	if (_is_public):
		AppInstance.config["variables"].erase(_content)
	else:
		AppInstance.document["variables"].erase(_content)
	get_parent().remove_child(self)


func _on_text_changed(new_text):
	_content["key"] = $NameText.text
	_content["value"] = $ValueText.text
	_content["desc"] = $DescText.text

func set_public(value: bool):
	_is_public = value
	var col: Color
	if value: 
		col = Color(0.7, 1, 0.75)
	else: 
		col = Color(1, 1, 1)
	$NameText.set("custom_colors/font_color", col)
