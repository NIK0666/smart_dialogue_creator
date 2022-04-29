tool
extends Node

var trans: Translation

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
var config: DialConfig
var config_path: String
# var document: Dictionary
var resource: Dialogue
var resource_path: String
var selected_branch: BranchCell = null
var loc_id: String = ""

func get_local_text(text_id: String):
	if (!trans):
		if TranslationServer.get_locale().to_lower().begins_with("ru"):
			trans = load("res://addons/SDC/locale/locale.ru.translation")
		else:
			trans = load("res://addons/SDC/locale/locale.en.translation")
	return trans.get_message(text_id)

func alert(text: String, title: String='Message') -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.window_title = title
	dialog.connect('modal_closed', dialog, 'queue_free')
	app_win.add_child(dialog)
	dialog.popup_centered()


func update_branches():
	exist_branches = []
	if resource != null:
		for dict in resource["Branches"]:
			exist_branches.append(dict["Name"])

func select_branch(node: BranchCell):
	if (selected_branch && selected_branch != node):
		deselect_branch(selected_branch)
	if selected_branch != node:
		selected_branch = node
		app_win.change_selected(node)

func rename_branch(old_name: String, new_name: String):
	
	for branch in resource["Branches"]:
		for ind in range(0, branch["Show"].size()):
			if (branch["Show"][ind] == old_name):
				branch["Show"][ind] = new_name
		
		for ind in range(0, branch["Hide"].size()):
			if (branch["Hide"][ind] == old_name):
				branch["Hide"][ind] = new_name


func deselect_branch(node: BranchCell):
	node.set_state("Default")

func delete_branch(node: BranchCell):
	resource["Branches"].erase(node.get_content())
	deselect_branch(node)
	node.get_parent().remove_child(node)
	if (resource["Branches"].size() > 0):
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
	for item in config["Characters"]:
		if id == item["Id"]:
			return item
	return {}

func get_character_id(name: String) -> String:
	for item in config["Characters"]:
		if name == item["Name"]:
			return item["Id"]
	return ""

func create_empty_dialog(path: String):
	var file = File.new()
	file.open(path, File.WRITE)
	var saved_json = JSON.print({"Character": "", "Autobranch": "", "Branches": []})
	file.store_string(saved_json)
	file.close()

func change_setting(name: String, value):
	settings.set_value("settings", name, value)
	settings.save("res://settings.cfg")

func load_settings():
	settings = ConfigFile.new()
	var err = settings.load("res://settings.cfg")
	if (settings.get_value("settings", "config") == null):
		change_setting("config", "")
		change_setting("last_file", "")
