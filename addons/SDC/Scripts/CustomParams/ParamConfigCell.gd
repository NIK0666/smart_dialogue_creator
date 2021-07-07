tool
extends HBoxContainer

var _content: Dictionary
var _is_public: bool
# Called when the node enters the scene tree for the first time.

func update_content(content: Dictionary):
	_content = content
	$NameText.text = content["Key"]
	$DescText.text = content["Desc"]

func _on_DelBtn_pressed():
	AppInstance.config.custom_parameters.erase(_content)
	get_parent().remove_child(self)


func _on_text_changed(new_text):
	_content["Key"] = $NameText.text
	_content["Desc"] = $DescText.text
