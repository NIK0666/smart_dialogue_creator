extends Control

class_name AppWin

onready var dialogs_list: VBoxContainer = $MainVBox/MainHBox/BranchesScroll/BranchesList
onready var path_input: LineEdit = $MainVBox/ToolbarPanel/HBoxContainer/PathInput
onready var info_scroll: ScrollContainer = $MainVBox/MainHBox/InfoScroll
onready var info_panel: Panel = $MainVBox/MainHBox/InfoScroll/InfoContainer/Panel
onready var info_container: ScrollContainer = $MainVBox/MainHBox/InfoScroll
onready var branches_scroll: ScrollContainer = $MainVBox/MainHBox/BranchesScroll
onready var phrases_list: VBoxContainer = $MainVBox/MainHBox/InfoScroll/InfoContainer/ScrollContainer/PhrasesVBox

var BranchCell = preload("res://Components/BranchCell.tscn")
var PhraseCell = preload("res://Components/DialPhraseCell.tscn")

func _ready():
	info_container.visible = false
	branches_scroll.visible = false
	AppInstance.app_win = self
	
	AppInstance.load_settings()
	AppInstance.load_config()
	randomize()


func _on_OpenDialog_file_selected(path):
	AppInstance.current_npc = AppInstance.load_json(path)
	init_form(path)
	AppInstance.change_setting("last_file", path)
	AppInstance.change_setting("last_path", $OpenDialog.current_dir + "/")

func _on_CreateDialog_file_selected(path):
	AppInstance.create_empty_dialog(path)
	AppInstance.current_npc = AppInstance.load_json(path)
	init_form(path)
	AppInstance.change_setting("last_file", path)
	AppInstance.change_setting("last_path", $CreateDialog.current_dir + "/")
	

func init_form(path: String):
	path_input.text = path
	branches_scroll.visible = true

	for item in dialogs_list.get_children():
		dialogs_list.remove_child(item)
	
	var content: Array = AppInstance.current_npc["dialogues"]
	for ind in range(content.size()):
		var cell = BranchCell.instance()
		cell.update_content(content[ind])
		dialogs_list.add_child(cell)
	
	AppInstance.update_branches()


func _on_SaveBtn_pressed():
	if AppInstance.current_npc.empty():
		AppInstance.alert("File is not opened!", "ERROR")
		return
	var file = File.new()
	file.open(path_input.text, File.WRITE)
	file.store_string(JSON.print(AppInstance.current_npc))
	file.close()


func _on_OpenBtn_pressed():
	show_filedialog($OpenDialog, "json")
	

func _on_NewBtn_pressed():
	show_filedialog($CreateDialog, "json")

func _on_ConfigPanel_new_config_dialog():
	show_filedialog($CreateConfig, "config")

func _on_ConfigPanel_open_config_dialog():
	show_filedialog($OpenConfig, "config")

func show_filedialog(node: FileDialog, type: String):
	node.current_path = AppInstance.settings.get_value("settings", "last_path")
	node.add_filter("*." + type)
	node.popup_centered()
	
func _on_AddBranchButton_pressed():
	
	if AppInstance.current_npc.empty():
		AppInstance.alert("Dialog is not found! Create or open file.", "ERROR")
		return
	
	var cell: BranchCell = BranchCell.instance()
	dialogs_list.add_child(cell)
	var new_dict: Dictionary = {
		"name": generate_name(), 
		"phrase": "", 
		"hidden": false, 
		"closed": false,
		"hide_self": true,
		"choice": false,
		"or_cond": false,
		"extern_signal": "",
		"show": [],
		"hide": [],
		"vars": [],
		"if": [],
		"dialog": []}
	AppInstance.current_npc["dialogues"].append(new_dict)
	cell.update_content(new_dict)
	cell.phrase_text.grab_focus()
	AppInstance.update_branches()

func _on_AddPhraseButton_pressed():
	var cell = PhraseCell.instance()
	phrases_list.add_child(cell)
	var new_dict: Dictionary = {
		"text": "",
		"npc": "", 
		"anim": "",
		"if": {}
		}
	AppInstance.selected_branch.get_content()["dialog"].append(new_dict)
	cell.update_content(new_dict)



func change_selected(node: BranchCell):
	
	if (node == null):
		info_container.visible = false
		return

	var node_content: Dictionary = node.get_content()
	info_container.visible = true
	info_panel.update_content(node_content)
	
	for item in phrases_list.get_children():
		phrases_list.remove_child(item)
	
	for item in node_content["dialog"]:
		var cell = PhraseCell.instance()
		phrases_list.add_child(cell)
		cell.update_content(item)
	
	update_branch_states()
	
func get_branch_cell(phrase_id: String) -> BranchCell:
	for item in dialogs_list.get_children():
		if (item.get_content()["name"] == phrase_id):
			return item
	return null


func update_branch_states():
	# Clean all states
	for item in dialogs_list.get_children():
		item.set_state("Default")
	
	var node_content: Dictionary = AppInstance.selected_branch.get_content()
	
	for item in node_content["show"]:
		var cell = get_branch_cell(item)
		if (cell):
			cell.set_state("WillShow")
		else:
			AppInstance.alert("Cell " + item + " not found on \"SHOW\" param in " + node_content["name"], "ERROR")
		
	for item in node_content["hide"]:
		var cell = get_branch_cell(item)
		if (cell):
			cell.set_state("WillHidden")
		else:
			AppInstance.alert("Cell " + item + " not found on \"HIDE\" param in " + node_content["name"], "ERROR")

	var cell = get_branch_cell(node_content["name"])
	cell.set_state("Selected")



func generate_name():
	var content: Array = AppInstance.current_npc["dialogues"]
	if (content.size() > 0):
		var temp_name: String = content[content.size() - 1]["name"]
		var temp_arr: Array = temp_name.split("_")
		if (temp_arr.size() > 1 && (temp_arr[temp_arr.size() - 1]).is_valid_integer()):
			var temp_num: int = (temp_arr[temp_arr.size() - 1]).to_int() + 1
			temp_name = ""
			for ind in range(0, temp_arr.size() - 1):
				temp_name = temp_name + temp_arr[ind] + "_"
			return temp_name + String(temp_num)
		else:
			return temp_name + "_1"
		
	else:
		return "branch_0"


func _on_ConfigBtn_pressed():
	$Panel/ConfigPanel.show()

func _on_Config_file_selected(path):
	$Panel/ConfigPanel.clean_data()
	AppInstance.change_setting("config", path)
	AppInstance.load_config()
	$Panel/ConfigPanel.load_data()

