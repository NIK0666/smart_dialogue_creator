extends Node

var compares: Array = ["==", "!=", ">=", "<=", ">", "<"]
var operators: Array = ["=", "+", "-", "*", "/"]
var exist_branches: Array = []
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
var document: Dictionary
var selected_branch: BranchCell = null

func alert(text: String, title: String='Message') -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.window_title = title
	dialog.connect('modal_closed', dialog, 'queue_free')
	app_win.add_child(dialog)
	dialog.popup_centered()


func update_branches():
	exist_branches = []
	for dict in document["branches"]:
		exist_branches.append(dict["name"])

func select_branch(node: BranchCell):
	if (selected_branch && selected_branch != node):
		deselect_branch(selected_branch)
	if selected_branch != node:
		selected_branch = node
		app_win.change_selected(node)

func rename_branch(old_name: String, new_name: String):
	
	for branch in document["branches"]:
		for ind in range(0, branch["show"].size()):
			if (branch["show"][ind] == old_name):
				branch["show"][ind] = new_name
		
		for ind in range(0, branch["hide"].size()):
			if (branch["hide"][ind] == old_name):
				branch["hide"][ind] = new_name


func deselect_branch(node: BranchCell):
	node.set_state("Default")

func delete_branch(node: BranchCell):
	document["branches"].erase(node.get_content())
	deselect_branch(node)
	node.get_parent().remove_child(node)
	if (document["branches"].size() > 0):
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

func get_character_info(id: String) -> Dictionary:
	for item in config["characters"]:
		if id == item["id"]:
			return item
	return {}

func get_character_id(name: String) -> String:
	for item in config["characters"]:
		if name == item["name"]:
			return item["id"]
	return ""

func create_empty_dialog(path: String):
	var file = File.new()
	file.open(path, File.WRITE)
	var saved_json = JSON.print({"character": "", "autobranch": "", "branches": []})
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
		change_setting("locale", TranslationServer.get_locale())
	if settings.get_value("settings", "locale"):
		TranslationServer.set_locale(settings.get_value("settings", "locale"))

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
