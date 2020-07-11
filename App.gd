extends Control

class_name AppWin

onready var dialogs_list: VBoxContainer = $MainVBox/MainHBox/BranchesScroll/BranchesList
onready var info_scroll: ScrollContainer = $MainVBox/MainHBox/ColorRect/InfoScroll
onready var info_panel: Panel = $MainVBox/MainHBox/ColorRect/InfoScroll/InfoContainer/Panel
onready var event_panel: Panel = $Panel/EventPanel
onready var info_container: ScrollContainer = $MainVBox/MainHBox/ColorRect/InfoScroll
onready var branches_scroll: ScrollContainer = $MainVBox/MainHBox/BranchesScroll
onready var phrases_list: VBoxContainer = $MainVBox/MainHBox/ColorRect/InfoScroll/InfoContainer/ScrollContainer/PhrasesVBox


var BranchCell = preload("res://Components/BranchCell.tscn")
var PhraseCell = preload("res://Components/DialPhraseCell.tscn")
var document_path: String = ""
var edit_mode: bool = false
var selected_branch_cell: BranchCell = null

func _ready():
	randomize()
	info_container.visible = false
	branches_scroll.visible = false
	AppInstance.app_win = self
	
	AppInstance.load_settings()
	AppInstance.load_config()
	
	var last_file_path = AppInstance.settings.get_value("settings", "last_file")
	var open_recent = AppInstance.load_json(last_file_path)
	if (open_recent):
		AppInstance.document = open_recent
		init_form(last_file_path)

func _on_OpenDialog_file_selected(path):
	AppInstance.document = AppInstance.load_json(path)
	init_form(path)
	AppInstance.change_setting("last_file", path)
	AppInstance.change_setting("last_path", $OpenDialog.current_dir + "/")

func _on_CreateDialog_file_selected(path):
	AppInstance.create_empty_dialog(path)
	AppInstance.document = AppInstance.load_json(path)
	init_form(path)
	AppInstance.change_setting("last_file", path)
	AppInstance.change_setting("last_path", $CreateDialog.current_dir + "/")
	

func init_form(path: String):
	document_path = path
	$MainVBox/BottomPanel/PathEdit.text = document_path
	branches_scroll.visible = true
	AppInstance.select_branch(null)
	$MainVBox/ToolbarPanel/HBoxContainer/CharacterBtn.set_text("")
	$MainVBox/ToolbarPanel/HBoxContainer/AutobranchBtn.set_text("")
	for item in dialogs_list.get_children():
		dialogs_list.remove_child(item)
	
	if (AppInstance.document.get("character")):
		$MainVBox/ToolbarPanel/HBoxContainer/CharacterBtn.update_content(AppInstance.get_character_info(AppInstance.document["character"]))
	if (AppInstance.document.get("autobranch")):
		$MainVBox/ToolbarPanel/HBoxContainer/AutobranchBtn.set_text(AppInstance.document["autobranch"])
	
	var content: Array = AppInstance.document["branches"]
	for ind in range(content.size()):
		var cell = BranchCell.instance()
		cell.update_content(content[ind])
		cell.set_edit_mode(edit_mode)
		dialogs_list.add_child(cell)
	
	AppInstance.update_branches()

func save_document():
	var file = File.new()
	file.open(document_path, File.WRITE)
	file.store_string(JSON.print(AppInstance.document))
	file.close()
	
	
func _on_SaveBtn_pressed():
	if AppInstance.document.empty():
		AppInstance.alert("File is not opened!", "ERROR")
		return
	save_document()


func _on_OpenBtn_pressed():
	show_filedialog($OpenDialog, "json")
	

func _on_NewBtn_pressed():
	show_filedialog($CreateDialog, "json")

func _on_ConfigPanel_new_config_dialog():
	show_filedialog($CreateConfig, "config")

func _on_ConfigPanel_open_config_dialog():
	show_filedialog($OpenConfig, "config")

func _on_ExportBtn_pressed():
	show_filedialog($ExportDialog, "loc")

func _on_ImportBtn_pressed():
	show_filedialog($ImportDialog, "loc")

func _on_ImportDialog_file_selected(path):
	var file = File.new()
	file.open(path, file.READ)
	
	var dict: Dictionary = {}
	var arr: Array = file.get_csv_line("\t")
	while arr.size() == 2:
		arr = file.get_csv_line("\t")
		if arr.size() == 2:
			dict[arr[0]] = arr[1]
	file.close()
	
	for branch in AppInstance.document["branches"]:
		if (dict.has(branch["text_id"])):
			branch["text"] = dict[branch["text_id"]]
		
		var ind:int = -1
		for phrase in branch["phrases"]:
			ind += 1
			if (dict.has(phrase["text_id"])):
				phrase["text"] = dict[phrase["text_id"]]
			elif (ind == 0):
				phrase["text"] = dict[branch["text_id"]]
				
	init_form(document_path)
	

func _on_ExportDialog_file_selected(path):
	var file_data: String = "text_id\ttext\n"
		
	for branch in AppInstance.document["branches"]:
		file_data += branch["text_id"] + "\t" + branch["text"] + "\n"
		var ind:int = -1
		for phrase in branch["phrases"]:
			ind += 1
			if (ind == 0 && String(branch["text"]) == String(phrase["text"])):
				continue
			file_data += phrase["text_id"] + "\t" + phrase["text"] + "\n"
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(file_data)
	file.close()



func show_filedialog(node: FileDialog, type: String):
	node.current_path = AppInstance.settings.get_value("settings", "last_path")
	node.add_filter("*." + type)
	node.popup_centered()
	
func _on_AddBranchButton_pressed():
	
	if AppInstance.document.empty():
		AppInstance.alert("Dialog is not found! Create or open file.", "ERROR")
		return
	
	var cell: BranchCell = BranchCell.instance()
	dialogs_list.add_child(cell)
	var new_dict: Dictionary = {
		"name": generate_name(), 
		"text": "", 
		"text_id": UUID.v4(),
		"hidden": false, 
		"closed": false,
		"hide_self": true,
		"choice": false,
		"or_cond": false,
		"event": {},
		"show": [],
		"hide": [],
		"vars": [],
		"if": [],
		"change_started": "", 
		"phrases": []}
	AppInstance.document["branches"].append(new_dict)
	cell.update_content(new_dict)
	cell.set_edit_mode(edit_mode)
	cell.phrase_text.grab_focus()
	AppInstance.update_branches()

func _on_AddPhraseButton_pressed():
	var cell = PhraseCell.instance()
	phrases_list.add_child(cell)
	var new_dict: Dictionary = {
		"text": "",
		"text_id": UUID.v4(),
		"npc": AppInstance.document["character"], 
		"anim": "",
		"if": {}
		}
	AppInstance.selected_branch.get_content()["phrases"].append(new_dict)
	cell.update_content(new_dict)

func change_selected_branch_text(value: String):
	var node_content: Dictionary = AppInstance.selected_branch.get_content()
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = (value != "" && node_content["phrases"].empty())

func change_selected(node: BranchCell):
	
	if (node == null):
		info_container.visible = false
		return
	
	if (selected_branch_cell != node):
		if selected_branch_cell != null:
			selected_branch_cell.update_phrase_text()
		selected_branch_cell = node

	var node_content: Dictionary = node.get_content()
	info_container.visible = true
	info_panel.update_content(node_content)
	for item in phrases_list.get_children():
		phrases_list.remove_child(item)
	
	for item in node_content["phrases"]:
		var cell = PhraseCell.instance()
		phrases_list.add_child(cell)
		cell.update_content(item)
	
	update_branch_states()
	
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = (node_content["text"] != "" && node_content["phrases"].empty())
	
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
	var content: Array = AppInstance.document["branches"]
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

func _on_PlayBtn_pressed():
	if AppInstance.document.empty():
		AppInstance.alert("File is not opened!", "ERROR")
		return
	
	save_document()
	$Panel/PlayPanel.show()

func _on_Config_file_selected(path):
	$Panel/ConfigPanel.clean_data()
	AppInstance.change_setting("config", path)
	AppInstance.load_config()
	$Panel/ConfigPanel.load_data()



func _on_AddFirst_pressed():
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = false
	
	var node_content: Dictionary = AppInstance.selected_branch.get_content()
	var cell = PhraseCell.instance()
	phrases_list.add_child(cell)
	var new_dict: Dictionary = {
		"text": node_content["text"],
		"text_id": UUID.v4(),
		"npc": AppInstance.config["hero"],
		"anim": "",
		"if": {}
		}
	node_content["phrases"].append(new_dict)
	cell.update_content(new_dict)


func _on_CharacterBtn_change_value():
	AppInstance.document["character"] = $MainVBox/ToolbarPanel/HBoxContainer/CharacterBtn.get_id()

func _on_AutobranchBtn_change_value():
	AppInstance.document["autobranch"] = $MainVBox/ToolbarPanel/HBoxContainer/AutobranchBtn.get_text()





func _on_EditBranchesBtn_toggled(button_pressed):
	edit_mode = button_pressed
	for cell in dialogs_list.get_children():
		cell.set_edit_mode(edit_mode)


