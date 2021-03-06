extends Panel

onready var chars_list = $HBoxContainer/CharactersList/ScrollContainer/ChanactersVBox
onready var vars_list = $HBoxContainer/VariablesList/ScrollContainer/VariablesVBox
onready var hero_btn = $HBoxContainer/CharactersList/Panel/HeroBtn

var CharCell = preload("res://Components/ConfigPanel/CharacterCell.tscn")
var VarCell = preload("res://Components/ConfigPanel/VariableCell.tscn")

signal new_config_dialog
signal open_config_dialog

func _ready():
	pass

func _on_CloseBtn_pressed():
	get_parent().visible = false
	self.visible = false
	clean_data()
	save_file()

func save_file():
	# Save config
	var config_file = File.new()
	config_file.open(AppInstance.settings.get_value("settings", "config"), File.WRITE)
	config_file.store_string(JSON.print(AppInstance.config))
	config_file.close()

func clean_data():
	for item in chars_list.get_children():
		chars_list.remove_child(item)

	for item in vars_list.get_children():
		vars_list.remove_child(item)
	
	hero_btn.update_content({})

func load_data():
	for item in AppInstance.config["characters"]:
		var cell = CharCell.instance()
		cell.update_content(item)
		chars_list.add_child(cell)

	if (AppInstance.document.has("variables")):
		for item in AppInstance.document["variables"]:
			var cell = VarCell.instance()
			cell.update_content(item)
			cell.set_public(false)
			vars_list.add_child(cell)


	for item in AppInstance.config["variables"]:
		var cell = VarCell.instance()
		cell.update_content(item)
		cell.set_public(true)
		vars_list.add_child(cell)
	
	hero_btn.update_content(AppInstance.get_character_info(AppInstance.config["hero"]))

func show():
	get_parent().visible = true
	self.visible = true
	load_data()

func _on_AdChardBtn_pressed():
	var cell = CharCell.instance()
	chars_list.add_child(cell)
	var new_dict: Dictionary = {
		"id": "",
		"name": ""
		}
	AppInstance.config["characters"].append(new_dict)
	cell.update_content(new_dict)


func _on_AddPublicVarBtn_pressed():
	var cell = VarCell.instance()
	vars_list.add_child(cell)
	var new_dict: Dictionary = {
		"key": "",
		"value": "",
		"desc": ""
		}
	AppInstance.config["variables"].append(new_dict)
	cell.update_content(new_dict)
	cell.set_public(true)

func _on_AddPrivateVarBtn_pressed():
	var cell = VarCell.instance()
	vars_list.add_child(cell)
	var new_dict: Dictionary = {
		"key": "",
		"value": "",
		"desc": ""
		}
	
	if (!AppInstance.document.has("variables")):
		AppInstance.document["variables"] = []
	AppInstance.document["variables"].append(new_dict)
	cell.update_content(new_dict)
	cell.set_public(false)

func _on_NewConfigBtn_pressed():
	save_file()
	emit_signal("new_config_dialog")


func _on_OpenBtn_pressed():
	save_file()
	emit_signal("open_config_dialog")


func _on_HeroBtn_change_value():
	if hero_btn._content.empty():
		AppInstance.config["hero"] = ""
	else:
		AppInstance.config["hero"] = hero_btn._content["id"]
