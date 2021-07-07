tool
extends Panel

onready var chars_list:VBoxContainer = $TabContainer/chars_list/ScrollContainer/ChanactersVBox
onready var public_vars_list:VBoxContainer = $TabContainer/public_variables/ScrollContainer/PublicVariablesVBox
onready var local_vars_list:VBoxContainer = $TabContainer/local_variables/ScrollContainer/LocalVariablesVBox
onready var custom_parameters_list:VBoxContainer = $TabContainer/custom_parameters/ScrollContainer/CustomParametersVBox
onready var hero_btn: PopupBtn = $TabContainer/chars_list/Panel/HeroBtn

var CharCell = preload("res://addons/SDC/Components/ConfigPanel/CharacterCell.tscn")
var VarCell = preload("res://addons/SDC/Components/ConfigPanel/VariableCell.tscn")
var ParamCell = preload("res://addons/SDC/Components/CustomParams/ParamConfigCell.tscn")

func _on_CloseBtn_pressed():
	get_parent().visible = false
	self.visible = false
	clean_data()
	save_file()

func save_file():
	ResourceSaver.save(AppInstance.config_path, AppInstance.config)

func clean_data():
	for item in chars_list.get_children():
		chars_list.remove_child(item)

	for item in public_vars_list.get_children():
		public_vars_list.remove_child(item)
		
	for item in local_vars_list.get_children():
		local_vars_list.remove_child(item)
	
	for item in custom_parameters_list.get_children():
		custom_parameters_list.remove_child(item)
	
	hero_btn.update_content({})

func load_data():
	for item in AppInstance.config["Characters"]:
		var cell = CharCell.instance()
		cell.update_content(item)
		chars_list.add_child(cell)

	if (AppInstance.resource != null):
		for item in AppInstance.resource["Variables"]:
			var cell = VarCell.instance()
			cell.update_content(item)
			cell.set_public(false)
			local_vars_list.add_child(cell)


	for item in AppInstance.config["Variables"]:
		var cell = VarCell.instance()
		cell.update_content(item)
		cell.set_public(true)
		public_vars_list.add_child(cell)
	
	for parameter in AppInstance.config["Custom_parameters"]:
		var cell = ParamCell.instance()
		cell.update_content(parameter)
		custom_parameters_list.add_child(cell)
	
	
	hero_btn.update_content(AppInstance.get_character_info(AppInstance.config["Hero"]))

func show():
	get_parent().visible = true
	self.visible = true
	load_data()

func _on_AdChardBtn_pressed():
	var cell = CharCell.instance()
	chars_list.add_child(cell)
	var new_dict: Dictionary = {
		"Id": "",
		"Name": ""
		}
	AppInstance.config["Characters"].append(new_dict)
	cell.update_content(new_dict)


func _on_AddPublicVarBtn_pressed():
	var cell = VarCell.instance()
	public_vars_list.add_child(cell)
	var new_dict: Dictionary = {
		"Key": "",
		"Value": "",
		"Desc": ""
		}
	AppInstance.config["Variables"].append(new_dict)
	cell.update_content(new_dict)
	cell.set_public(true)

func _on_AddPrivateVarBtn_pressed():
	var cell = VarCell.instance()
	local_vars_list.add_child(cell)
	var new_dict: Dictionary = {
		"Key": "",
		"Value": "",
		"Desc": ""
		}
	
	if (AppInstance.resource != null):
		AppInstance.resource["Variables"].append(new_dict)
	cell.update_content(new_dict)
	cell.set_public(false)


func _on_HeroBtn_change_value():
	if hero_btn._content.empty():
		AppInstance.config["Hero"] = ""
	else:
		AppInstance.config["Hero"] = hero_btn._content["Id"]


func _on_AddCustomParameterBtn_pressed():
	var cell = ParamCell.instance()
	custom_parameters_list.add_child(cell)
	var new_dict: Dictionary = {
		"Key": "",
		"Value": "",
		"Desc": ""
		}
	AppInstance.config["Custom_parameters"].append(new_dict)
	cell.update_content(new_dict)

