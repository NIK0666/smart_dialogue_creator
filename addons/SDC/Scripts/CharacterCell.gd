tool
extends HBoxContainer

var _content: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_content(content: Dictionary):
	_content = content
	$IdText.text = content["Id"]
	$NameText.text = content["Name"]

func _on_DelBtn_pressed():
	AppInstance.config["Characters"].erase(_content)
	get_parent().remove_child(self)

func _on_text_changed(new_text):
	_content["Id"] = $IdText.text
	_content["Name"] = $NameText.text
