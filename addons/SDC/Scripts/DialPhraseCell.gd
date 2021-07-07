tool
extends VBoxContainer

var _content: Dictionary

func _ready():
	pass # Replace with function body.

func update_content(content: Dictionary):
	_content = content
	$HBoxContainer/NPCNameText.update_content(AppInstance.get_character_info(content["Npc"]))
	$HBoxContainer/AnimationText.text = content["Anim"]
	$PhraseText.text = content["Text"]
	
	$PhraseText.rect_size.x = get_parent().rect_size.x - 12 # Text height change Crutch fix
	$PhraseText._on_TextEdit_text_changed()
	
	if (_content["If"].empty()):
		$HBoxContainer/Control/VarCondText.set_text("")
		$HBoxContainer/Control/OpCondText.text = "=="
		$HBoxContainer/Control/ValCondText.text = ""
		
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("Random")
		if (content.has("Random")):
			$HBoxContainer/Control/ElseCheckBox.pressed = content["Random"]
		else:
			$HBoxContainer/Control/ElseCheckBox.pressed = false
	else:
		$HBoxContainer/Control/VarCondText.set_text(content["If"]["Key"])
		$HBoxContainer/Control/OpCondText.text = content["If"]["Op"]
		$HBoxContainer/Control/ValCondText.text = content["If"]["Value"]
		$HBoxContainer/Control/ElseCheckBox.pressed = content["If"]["Else"]
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("Else")

func _on_NPCNameText_change_value():
	_content["Npc"] = $HBoxContainer/NPCNameText.get_id()

func _on_AnimationText_text_changed(new_text):
	_content["Anim"] = new_text

func _on_CondText_text_changed(new_text):
	save_cond_info()

func _on_ElseCheckBox_toggled(button_pressed):
	if (_content["If"].empty()):
		_content["Random"] = button_pressed
	else:
		save_cond_info()

func save_cond_info():
	var is_set: bool = !($HBoxContainer/Control/VarCondText.get_text().empty() && $HBoxContainer/Control/VarCondText.get_text().empty())
	if (is_set):
		_content["If"] = {
			"Key": $HBoxContainer/Control/VarCondText.get_text(),
			"Op": $HBoxContainer/Control/OpCondText.text,
			"Value": $HBoxContainer/Control/ValCondText.text,
			"Else": $HBoxContainer/Control/ElseCheckBox.pressed
			}
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("Else")
	else:
		_content["If"] = {}
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("Random")

func _on_PhraseText_text_changed():
	_content["Text"] = $PhraseText.text


func _on_DelBtn_pressed():
	print(AppInstance.selected_branch)
	AppInstance.selected_branch.get_content()["Phrases"].erase(_content)
	get_parent().remove_child(self)


func _on_DownBtn_pressed():
	var branch_content: Dictionary = AppInstance.selected_branch.get_content()
	var ind = get_index()
	if (branch_content["Phrases"].size() > ind + 1):
		branch_content["Phrases"].remove(ind)
		branch_content["Phrases"].insert(ind + 1, _content)
		var next_cell = AppInstance.app_win.phrases_list.get_child(ind + 1)
		next_cell.update_content(branch_content["Phrases"][ind + 1])
		update_content(branch_content["Phrases"][ind])

func _on_UpBtn_pressed():
	var branch_content: Dictionary = AppInstance.selected_branch.get_content()
	var ind = get_index()
	if (ind > 0):
		branch_content["Phrases"].remove(ind)
		branch_content["Phrases"].insert(ind - 1, _content)
		var prev_cell = AppInstance.app_win.phrases_list.get_child(ind - 1)
		prev_cell.update_content(branch_content["Phrases"][ind - 1])
		update_content(branch_content["Phrases"][ind])

func _on_ParamsBtn_pressed():
	if (!_content.has("Custom_params")):
		_content["Custom_params"] = {}
	
	for param_info in AppInstance.config.Custom_parameters:
		if (!_content["Custom_params"].has(param_info.Key)):
			_content["Custom_params"][param_info.Key] = param_info.Value
	
	AppInstance.app_win.custom_params_panel.show_with_content(_content["Custom_params"])
