tool
extends MenuButton

class_name PopupBtn

signal change_value

export var placeholder: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().connect("id_pressed", self, "_on_item_pressed")
	connect("pressed", self, "_on_pressed")
	
	if (placeholder != ""):
		hint_tooltip = AppInstance.get_local_text(placeholder)
		get_popup().add_item(hint_tooltip)
		set_text(hint_tooltip)
		

func _on_item_pressed(id: int):
	var item_text: String = get_popup().get_item_text(id)
	selected_item(id)
	if (get_text() != item_text):
		set_text(item_text)
		emit_signal("change_value")
	
func _on_pressed():
	get_popup().clear()
	if (placeholder != ""):
		get_popup().add_item(hint_tooltip)
	update_popup_list()


func set_text(value: String):
	if ((value == "" && placeholder != "") || (value == placeholder)):
		.set_text(hint_tooltip)
		self_modulate.a = 0.33
	else:
		.set_text(value)
		self_modulate.a = 1

func get_text() -> String:
	if (text == placeholder):
		return ""
	else:
		return .get_text()

func update_popup_list(): # Overradable
	pass

func selected_item(id: int): # Overradable
	pass
