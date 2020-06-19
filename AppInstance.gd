extends Node

var compares: Array = ["==", "!=", ">=", "<=", ">", "<"]
var operators: Array = ["=", "+", "-", "*", "/"]
var exist_branches: Array = ["none"]
var colors: Dictionary = {
	"Default": Color("2c2a32"),
	"Selected": Color("00cdcf"),
	"WillHidden": Color("e7b0b0"),
	"WillShow": Color("93d2a9"),
	"Hidden": Color("666666"),
	"Close": Color("c6cd88")
}

var app_win: AppWin = null
var settings:ConfigFile
var config: Dictionary
var current_npc: Dictionary
var selected_branch: BranchCell = null

func alert(text: String, title: String='Message') -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.window_title = title
	dialog.connect('modal_closed', dialog, 'queue_free')
	app_win.add_child(dialog)
	dialog.popup_centered()


func update_branches():
	exist_branches = ["none"]
	for dict in current_npc["dialogues"]:
		exist_branches.append(dict["name"])

func select_branch(node: BranchCell):
	if (selected_branch && selected_branch != node):
		deselect_branch(selected_branch)
	if selected_branch != node:
		selected_branch = node
		app_win.change_selected(node)

func deselect_branch(node: BranchCell):
	node.set_state("Default")

func delete_branch(node: BranchCell):
	current_npc["dialogues"].erase(node.get_content())
	deselect_branch(node)
	node.get_parent().remove_child(node)
	if (current_npc["dialogues"].size() > 0):
		select_branch(app_win.dialogs_list.get_child(0))
	else:
		select_branch(null)

func load_json(path: String):
	var file = File.new()
	file.open(path, file.READ)
	var content = file.get_as_text()
	file.close()
	
	var result_json = JSON.parse(content)
	if result_json.error == OK:
		return result_json.result
	else:
		return null 

func get_character_name(id: String) -> String:
	for item in config["characters"]:
		if id == item["id"]:
			return item["name"]
	return ""

func get_character_id(name: String) -> String:
	for item in config["characters"]:
		if name == item["name"]:
			return item["id"]
	return ""

func create_empty_dialog(path: String):
	var file = File.new()
	file.open(path, File.WRITE)
	var saved_json = JSON.print({"name": "", "autodialog": null, "dialogues": []})
	file.store_string(saved_json)
	file.close()

func change_setting(name: String, value):
	settings.set_value("settings", name, value)
	settings.save("res://settings.cfg")

func load_settings():
	settings = ConfigFile.new()
	var err = settings.load("res://settings.cfg")
	if (settings.get_value("settings", "config") == null):
		change_setting("config", "res://Default.config")
		change_setting("last_path", "res://")
		change_setting("last_file", "")

func load_config():
	var dict = load_json(settings.get_value("settings", "config"))
	if (dict == null):
		var file = File.new()
		file.open(settings.get_value("settings", "config"), File.WRITE)
		config = {"characters": [], "variables": [], "hero": ""}
		var saved_json = JSON.print(config)
		file.store_string(saved_json)
		file.close()
	else:
		config = dict
