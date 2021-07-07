tool
extends HBoxContainer

var _content: Dictionary
var _is_public: bool
# Called when the node enters the scene tree for the first time.

func update_content(content: Dictionary):
	_content = content
	$NameText.text = content["Key"]
	$ValueText.text = content["Value"]
	$DescText.text = content["Desc"]

func _on_DelBtn_pressed():
	if (_is_public):
		AppInstance.config["Variables"].erase(_content)
	else:
		AppInstance.resource["Variables"].erase(_content)
	get_parent().remove_child(self)


func _on_text_changed(new_text):
	_content["Key"] = $NameText.text
	_content["Value"] = $ValueText.text
	_content["Desc"] = $DescText.text

func set_public(value: bool):
	_is_public = value
	var col: Color
	if value: 
		col = Color(0.7, 1, 0.75)
	else: 
		col = Color(1, 1, 1)
	$NameText.set("custom_colors/font_color", col)
