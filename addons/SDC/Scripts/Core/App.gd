tool
extends Panel

class_name AppWin

onready var dialogs_list: VBoxContainer = $MainVBox/MainHBox/BranchesScroll/BranchesList
onready var info_scroll: ScrollContainer = $MainVBox/MainHBox/ColorRect/InfoScroll
onready var info_panel: Panel = $MainVBox/MainHBox/ColorRect/InfoScroll/InfoContainer/Panel
onready var event_panel: Panel = $Panel/EventPanel
onready var file_panel: Panel = $Panel/FilePanel
onready var custom_params_panel: Panel = $Panel/CustomParamsPanel
onready var info_container: ScrollContainer = $MainVBox/MainHBox/ColorRect/InfoScroll
onready var branches_scroll: ScrollContainer = $MainVBox/MainHBox/BranchesScroll
onready var phrases_list: VBoxContainer = $MainVBox/MainHBox/ColorRect/InfoScroll/InfoContainer/ScrollContainer/PhrasesVBox


var BranchCell = preload("res://addons/SDC/Components/BranchCell.tscn")
var PhraseCell = preload("res://addons/SDC/Components/DialPhraseCell.tscn")
var edit_mode: bool = false
var selected_branch_cell: BranchCell = null
var own_plugin

func _ready():
	
	info_container.visible = false
	branches_scroll.visible = false
	AppInstance.app_win = self
	
	AppInstance.load_settings()
	
	var config_path = AppInstance.settings.get_value("settings", "config")
	var file2Check = File.new()
	if (file2Check.file_exists(config_path)):
		AppInstance.config = load(config_path)
		AppInstance.config_path = config_path


func _on_OpenJSON_file_selected(path): # JSON to RES
	var document:Dictionary = AppInstance.load_json(path)
	AppInstance.change_setting("last_file", path)
	AppInstance.change_setting("last_path", $JsonToResDialog.current_dir + "/")
	
	AppInstance.resource.Character = document["Character"]
	AppInstance.resource.Autobranch = document["Autobranch"]
	if (document.has("Branches")):
		AppInstance.resource.Branches = document["Branches"]
	if (document.has("Variables")):
		AppInstance.resource.Variables = document["Variables"]
	ResourceSaver.save(AppInstance.resource_path, AppInstance.resource)
	init_form()



func init_form():	
	$MainVBox/ToolbarPanel/HBoxContainer/PathEdit.text = AppInstance.resource_path
	
	branches_scroll.visible = true
	AppInstance.select_branch(null)
	$MainVBox/ToolbarPanel/HBoxContainer/CharacterBtn.set_text("")
	$MainVBox/ToolbarPanel/HBoxContainer/AutobranchBtn.set_text("")
	for item in dialogs_list.get_children():
		dialogs_list.remove_child(item)
	
	$MainVBox/ToolbarPanel/HBoxContainer/CharacterBtn.update_content(AppInstance.get_character_info(AppInstance.resource.Character))
	if (AppInstance.resource.get("Autobranch")):
		$MainVBox/ToolbarPanel/HBoxContainer/AutobranchBtn.set_text(AppInstance.resource["Autobranch"])
	
	var content: Array = AppInstance.resource["Branches"]
	for ind in range(content.size()):
		var cell = BranchCell.instance()
		cell.update_content(content[ind])
		cell.set_edit_mode(edit_mode)
		dialogs_list.add_child(cell)
	
	AppInstance.update_branches()

func save_document():
	if (AppInstance.resource):
		var file2Check = File.new()
		if (file2Check.file_exists(AppInstance.resource_path)):
			ResourceSaver.save(AppInstance.resource_path, AppInstance.resource)
		else:
			print("ERROR: Incorrect resource path!")
	else:
		print("ERROR: Resource is not opened!")
	
	
func _on_SaveBtn_pressed():
	save_document()
	ResourceSaver.save(AppInstance.config_path, AppInstance.config)


func open(res: Dialogue, path: String, save_settings: bool = true):
	AppInstance.resource = res
	AppInstance.resource_path = path
	if (AppInstance.resource != null):
		init_form()
	if (save_settings):
		AppInstance.change_setting("last_file", path)

func show():
	.show()
	if (AppInstance.resource == null):
		var res_path = AppInstance.settings.get_value("settings", "last_file")
		if (res_path && res_path != ""):
			open(load(res_path), res_path, false)
		if AppInstance.config == null:
			AppInstance.alert("Config resource is not set!")


func set_config(res: DialConfig, path: String):
	AppInstance.config = res
	AppInstance.config_path = path
	AppInstance.change_setting("config", path)
	AppInstance.update_branches()
	
func _on_NewDialogBtn_pressed():
	show_filedialog($CreateDialog, "tres")
	close_file_panel()

func _on_CreateDialog_file_selected(path: String):
	var new_dial: Dialogue = Dialogue.new()
	ResourceSaver.save(path, new_dial)	
	open(new_dial, path)
	
func _on_OpenDialogBtn_pressed():
	show_filedialog($OpenDialog, "tres")
	close_file_panel()

func _on_OpenDialog_file_selected(path):
	AppInstance.resource = load(path)
	AppInstance.resource_path = path
	
	AppInstance.change_setting("last_file", path)
	AppInstance.change_setting("last_path", $JsonToResDialog.current_dir + "/")
	
	init_form()
func _on_NewConfigBtn_pressed():
	show_filedialog($CreateConfig, "tres")
	close_file_panel()

func _on_CreateConfig_file_selected(path: String):
	var new_config: DialConfig = DialConfig.new()
	ResourceSaver.save(path, new_config)
	set_config(new_config, path)

func _on_OpenConfigBtn_pressed():
	show_filedialog($OpenConfig, "tres")
	close_file_panel()
	
func _on_OpenConfig_file_selected(path: String):
	set_config(load(path), path)	






func _on_ExportBtn_pressed():
	show_filedialog($ExportDialog, "csv")
	close_file_panel()

func _on_ImportBtn_pressed():
	show_filedialog($ImportDialog, "csv")
	close_file_panel()

func _on_ImportDialog_file_selected(path):
	var file = File.new()
	file.open(path, file.READ)
	
	
#	"Panel/FilePanel/VBoxContainer/ImportBtn/ImportColumnLineEdit"
	var column: int = int($Panel/FilePanel/VBoxContainer/ImportConfigPanel/ImportColumnLineEdit.text)
	var lang_id: String = $Panel/FilePanel/VBoxContainer/ImportConfigPanel/ImportLangLineEdit.text
	
	var dict: Dictionary = {}
	var arr: Array = file.get_csv_line("\t")

	arr = file.get_csv_line("\t")
	while arr.size() > column:
		dict[arr[2]] = arr[column]
		arr = file.get_csv_line("\t")
	file.close()
	
	for branch in AppInstance.resource["Branches"]:
		if (lang_id == ""):
			if (dict.has(branch["Text_id"])):
				branch["Text"] = dict[branch["Text_id"]]
			
			var ind:int = -1
			for phrase in branch["Phrases"]:
				ind += 1
				if (dict.has(phrase["Text_id"])):
					phrase["Text"] = dict[phrase["Text_id"]]
				elif (ind == 0 && branch["Text"] != ""):
					phrase["Text"] = dict[branch["Text_id"]]
		else:
			if (dict.has(branch["Text_id"])):
				if (!branch.has("Loc")):
					branch["Loc"] = {}
				branch["Loc"][lang_id] = dict[branch["Text_id"]]
			
			var ind:int = -1
			for phrase in branch["Phrases"]:
				ind += 1
				if (dict.has(phrase["Text_id"])):
					if (!phrase.has("Loc")):
						phrase["Loc"] = {}
					phrase["Loc"][lang_id] = dict[phrase["Text_id"]]
				elif (ind == 0 && branch["Text"] != ""):
					if (!phrase.has("Loc")):
						phrase["Loc"] = {}
					phrase["Loc"][lang_id] = dict[branch["Text_id"]]
	

func _on_ExportDialog_file_selected(path):
	var file_data: String = "branch_name\tcharacter_id\ttext_id\toriginal_text\n"
		
	for branch in AppInstance.resource.Branches:
		if (branch["Text"] != ""):
			file_data += branch["Name"] + "\t" + AppInstance.config["Hero"] + "\t" + branch["Text_id"] + "\t" + branch["Text"] + "\n"
		var ind:int = -1
		for phrase in branch["Phrases"]:
			ind += 1
			if (ind == 0 && String(branch["Text"]) == String(phrase["Text"])):
				continue
			file_data += branch["Name"] + "\t" + phrase["Npc"] + "\t" + phrase["Text_id"] + "\t" + phrase["Text"] + "\n"
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(file_data)
	file.close()


func show_filedialog(node: FileDialog, type: String, custom_path: String = ""):
	if (custom_path == ""):
		node.current_path = AppInstance.resource_path.get_basename()
	else:
		node.current_path = custom_path + "/" + AppInstance.resource_path.get_file().get_basename()
	if (node.filters.size() == 0):
		node.add_filter("*." + type)
	node.popup_centered()

func _on_AddBranchButton_pressed():
	
	if AppInstance.resource == null:
		AppInstance.alert("Dialog is not found! Create or open file.", "ERROR")
		return
	
	var cell: BranchCell = BranchCell.instance()
	dialogs_list.add_child(cell)
	var new_dict: Dictionary = {
		"Name": generate_name(), 
		"Text": "", 
		"Text_id": UUID.v4(),
		"Hidden": false, 
		"Closed": false,
		"Hide_self": true,
		"Choice": false,
		"Or_cond": false,
		"Event": {},
		"Show": [],
		"Hide": [],
		"Vars": [],
		"If": [],
		"Change_started": "", 
		"Phrases": []}
	AppInstance.resource["Branches"].append(new_dict)
	cell.update_content(new_dict)
	cell.set_edit_mode(edit_mode)
	cell.phrase_text.grab_focus()
	AppInstance.update_branches()

func _on_AddPhraseButton_pressed():
	var cell = PhraseCell.instance()
	phrases_list.add_child(cell)
	var new_dict: Dictionary = {
		"Text": "",
		"Text_id": UUID.v4(),
		"Npc": AppInstance.resource["Character"], 
		"Anim": "",
		"Custom_params": {},
		"Random": false,
		"If": {}
		}
	AppInstance.selected_branch.get_content()["Phrases"].append(new_dict)
	cell.update_content(new_dict)
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = false

func change_selected_branch_text(value: String):
	var node_content: Dictionary = AppInstance.selected_branch.get_content()
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = (value != "" && node_content["Phrases"].empty())

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
	
	for item in node_content["Phrases"]:
		var cell = PhraseCell.instance()
		phrases_list.add_child(cell)
		cell.update_content(item)
	
	update_branch_states()
	
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = (node_content["Text"] != "" && node_content["Phrases"].empty())
	
func get_branch_cell(phrase_id: String) -> BranchCell:
	for item in dialogs_list.get_children():
		if (item.get_content()["Name"] == phrase_id):
			return item
	return null


func update_branch_states():
	# Clean all states
	for item in dialogs_list.get_children():
		item.set_state("Default")
	
	var node_content: Dictionary = AppInstance.selected_branch.get_content()
	
	for item in node_content["Show"]:
		var cell = get_branch_cell(item)
		if (cell):
			cell.set_state("WillShow")
		else:
			AppInstance.alert("Cell " + item + " not found on \"SHOW\" param in " + node_content["Name"], "ERROR")
		
	for item in node_content["Hide"]:
		var cell = get_branch_cell(item)
		if (cell):
			cell.set_state("WillHidden")
		else:
			AppInstance.alert("Cell " + item + " not found on \"HIDE\" param in " + node_content["Name"], "ERROR")

	var cell = get_branch_cell(node_content["Name"])
	cell.set_state("Selected")



func generate_name():
	var content: Array = AppInstance.resource["Branches"]
	if (content.size() > 0):
		var temp_name: String = content[content.size() - 1]["Name"]
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
	if AppInstance.resource == null:
		AppInstance.alert("File is not opened!", "ERROR")
		return
	
	save_document()
	$Panel/PlayPanel.show()


func _on_AddFirst_pressed():
	
	$MainVBox/MainHBox/ColorRect/AddFirst.visible = false
	
	var node_content: Dictionary = AppInstance.selected_branch.get_content()
	var cell = PhraseCell.instance()
	phrases_list.add_child(cell)
	var new_dict: Dictionary = {
		"Text": node_content["Text"],
		"Text_id": UUID.v4(),
		"Npc": AppInstance.config["Hero"],
		"Anim": "",
		"Custom_params": {},
		"Random": false,
		"If": {}
		}
	node_content["Phrases"].append(new_dict)
	cell.update_content(new_dict)


func _on_CharacterBtn_change_value():
	AppInstance.resource["Character"] = $MainVBox/ToolbarPanel/HBoxContainer/CharacterBtn.get_id()

func _on_AutobranchBtn_change_value():
	AppInstance.resource["Autobranch"] = $MainVBox/ToolbarPanel/HBoxContainer/AutobranchBtn.get_text()





func _on_EditBranchesBtn_toggled(button_pressed):
	edit_mode = button_pressed
	for cell in dialogs_list.get_children():
		cell.set_edit_mode(edit_mode)
	close_file_panel()

func _on_ImportJSONBtn_pressed():
	show_filedialog($JsonToResDialog, "json", AppInstance.export_dial_path)
	close_file_panel()


func _on_ExpoprtJSONBtn_pressed():
	show_filedialog($ResToJsonDialog, "json", AppInstance.export_dial_path)
	close_file_panel()

func _on_ResToJsonDialog_file_selected(path: String): #RES to JSON
	
	var res_path_arr: Array = AppInstance.resource_path.split("/");
	var res_id: String = res_path_arr[res_path_arr.size() - 1].split(".tres")[0];
	
	var document:Dictionary = {
		"Id": res_id,
		"Character": AppInstance.resource.Character,
		"Autobranch": AppInstance.resource.Autobranch,
		"Branches": AppInstance.resource.Branches,
		"Variables": AppInstance.resource.Variables
		}
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(to_json(document))
	file.close()
	
	AppInstance.export_dial_path = path.get_base_dir()


func _on_EsportConfigToJSONBtn_pressed():
	show_filedialog($ResToJsonConfig, "json")
	close_file_panel()

func _on_ResToJsonConfig_file_selected(path):
	var document:Dictionary = {
		"Hero": AppInstance.config["Hero"],
		"Characters": AppInstance.config.Characters,
		"Variables": AppInstance.config.Variables,
		"Custom_parameters": AppInstance.config.Custom_parameters
		}
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(to_json(document))
	file.close()

func _on_FilePanelCloseBtn_pressed():
	close_file_panel()

func close_file_panel():
	file_panel.get_parent().visible = false
	file_panel.visible = false

func _on_FileBtn_pressed():
	file_panel.get_parent().visible = true
	file_panel.visible = true


func _on_LocLineEdit_text_entered(new_text):
	AppInstance.loc_id = new_text
