tool
extends HBoxContainer

var _content: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_content(content: Dictionary):
	_content = content
	$IdText.text = content["id"]
	$NameText.text = content["name"]

func _on_DelBtn_pressed():
	AppInstance.config["characters"].erase(_content)
	get_parent().remove_child(self)

func _on_text_changed(new_text):
	_content["id"] = $IdText.text
	_content["name"] = $NameText.text
