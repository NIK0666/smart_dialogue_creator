extends MenuButton

export var is_compare: bool = true
signal change_value

# Called when the node enters the scene tree for the first time.
func _ready():
	if (is_compare):
		for item in AppInstance.compares:
			get_popup().add_item(item)
	else:
		for item in AppInstance.operators:
			get_popup().add_item(item)
	get_popup().connect("id_pressed", self, "_on_item_pressed")


func _on_item_pressed(id: int):
	var item_text: String = get_popup().get_item_text(id)
	if (text != item_text):
		text = item_text
		emit_signal("change_value")
