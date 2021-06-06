tool
extends HBoxContainer

var _content: Dictionary
signal RemoveParam(key)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_content(key: String, value: String):
	$KeyText.text = key
	$ValueText.text = value

func _on_DelBtn_pressed():
	emit_signal("RemoveParam", get_key())
	get_parent().remove_child(self)

func get_key() -> String:
	return $KeyText.text

func get_value() -> String:
	return $ValueText.text
