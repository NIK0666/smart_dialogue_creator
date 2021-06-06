tool
extends VBoxContainer

var _content: Dictionary

func _ready():
	pass # Replace with function body.

func update_content(content: Dictionary):
	_content = content
	$HBoxContainer/NPCNameText.update_content(AppInstance.get_character_info(content["npc"]))
	$HBoxContainer/AnimationText.text = content["anim"]
	$PhraseText.text = content["text"]
	
	$PhraseText.rect_size.x = get_parent().rect_size.x - 12 # Text height change Crutch fix
	$PhraseText._on_TextEdit_text_changed()
	
	if (_content["if"].empty()):
		$HBoxContainer/Control/VarCondText.set_text("")
		$HBoxContainer/Control/OpCondText.text = "=="
		$HBoxContainer/Control/ValCondText.text = ""
		
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("random")
		if (content.has("random")):
			$HBoxContainer/Control/ElseCheckBox.pressed = content["random"]
		else:
			$HBoxContainer/Control/ElseCheckBox.pressed = false
	else:
		$HBoxContainer/Control/VarCondText.set_text(content["if"]["key"])
		$HBoxContainer/Control/OpCondText.text = content["if"]["op"]
		$HBoxContainer/Control/ValCondText.text = content["if"]["value"]
		$HBoxContainer/Control/ElseCheckBox.pressed = content["if"]["else"]
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("else")

func _on_NPCNameText_change_value():
	_content["npc"] = $HBoxContainer/NPCNameText.get_id()

func _on_AnimationText_text_changed(new_text):
	_content["anim"] = new_text

func _on_CondText_text_changed(new_text):
	save_cond_info()

func _on_ElseCheckBox_toggled(button_pressed):
	if (_content["if"].empty()):
		_content["random"] = button_pressed
	else:
		save_cond_info()

func save_cond_info():
	var is_set: bool = !($HBoxContainer/Control/VarCondText.get_text().empty() && $HBoxContainer/Control/VarCondText.get_text().empty())
	if (is_set):
		_content["if"] = {
			"key": $HBoxContainer/Control/VarCondText.get_text(),
			"op": $HBoxContainer/Control/OpCondText.text,
			"value": $HBoxContainer/Control/ValCondText.text,
			"else": $HBoxContainer/Control/ElseCheckBox.pressed
			}
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("else")
	else:
		_content["if"] = {}
		$HBoxContainer/Control/ElseCheckBox.text = AppInstance.get_local_text("random")

func _on_PhraseText_text_changed():
	_content["text"] = $PhraseText.text


func _on_DelBtn_pressed():
	print(AppInstance.selected_branch)
	AppInstance.selected_branch.get_content()["phrases"].erase(_content)
	get_parent().remove_child(self)


func _on_DownBtn_pressed():
	var branch_content: Dictionary = AppInstance.selected_branch.get_content()
	var ind = get_index()
	if (branch_content["phrases"].size() > ind + 1):
		branch_content["phrases"].remove(ind)
		branch_content["phrases"].insert(ind + 1, _content)
		var next_cell = AppInstance.app_win.phrases_list.get_child(ind + 1)
		next_cell.update_content(branch_content["phrases"][ind + 1])
		update_content(branch_content["phrases"][ind])

func _on_UpBtn_pressed():
	var branch_content: Dictionary = AppInstance.selected_branch.get_content()
	var ind = get_index()
	if (ind > 0):
		branch_content["phrases"].remove(ind)
		branch_content["phrases"].insert(ind - 1, _content)
		var prev_cell = AppInstance.app_win.phrases_list.get_child(ind - 1)
		prev_cell.update_content(branch_content["phrases"][ind - 1])
		update_content(branch_content["phrases"][ind])

func _on_ParamsBtn_pressed():
	if (!_content.has("custom_params")):
		_content["custom_params"] = {}
	
	for param_info in AppInstance.config.custom_parameters:
		if (!_content["custom_params"].has(param_info.key)):
			_content["custom_params"][param_info.key] = param_info.value
	
	AppInstance.app_win.custom_params_panel.show_with_content(_content["custom_params"])
