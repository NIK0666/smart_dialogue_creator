extends MenuButton

signal change_value

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().connect("id_pressed", self, "_on_item_pressed")

func _on_item_pressed(id: int):
	var item_text: String = get_popup().get_item_text(id)
	if (text != item_text):
		text = item_text
		emit_signal("change_value")
	
	if (id == 0):
		self_modulate.a = 0.33
	else:
		self_modulate.a = 1
	
func _on_LineEdit_pressed():
	get_popup().clear()
	update_popup_list()

func update_popup_list():
	for item in AppInstance.exist_branches:
		get_popup().add_item(item)
