tool
extends ColorRect

class_name BranchCell

onready var name_text:LineEdit = $HBoxContainer/NameText
onready var phrase_text:LineEdit = $HBoxContainer/PhraseText

var _content: Dictionary
var old_name: String

func _ready():
	set_state("Default")

func update_content(content: Dictionary):
	_content = content
	$HBoxContainer/NameText.text = _content["Name"]
	update_phrase_text()

func update_phrase_text():
	if (_content.has("Text") && _content["Text"] != ""):
		$HBoxContainer/PhraseText.text = _content["Text"]
	elif _content["Phrases"].size() > 0:
		$HBoxContainer/PhraseText.text = ""
		$HBoxContainer/PhraseText.placeholder_text = _content["Phrases"][0]["Text"]

func _on_Button_pressed():
	pass
	# AppInstance.request_service(_content["Source"]["Text"])


func _on_PhraseText_text_changed(new_text):
	_content["Text"] = new_text
	AppInstance.app_win.change_selected_branch_text(new_text)

func _on_NameText_text_changed(new_text):
	_content["Name"] = new_text
	AppInstance.update_branches()
	


func _on_NameText_focus_entered():
	AppInstance.select_branch(self)
	old_name = _content["Name"]
	
func set_state(state_name: String):
	self.color = AppInstance.colors[state_name]
	if (!_content.empty() && _content["Closed"]):
		$HBoxContainer/PhraseText.set("custom_colors/font_color", AppInstance.colors["Close"])
	else:
		$HBoxContainer/PhraseText.set("custom_colors/font_color", Color("ffffff"))
	
	if (!_content.empty() && _content["Hidden"]):
		$HBoxContainer/NameText.set("custom_colors/font_color", AppInstance.colors["Hidden"])
	else:
		$HBoxContainer/NameText.set("custom_colors/font_color", Color("ffffff"))

func get_content() -> Dictionary:
	return _content


func _on_DelBtn_pressed():
	AppInstance.delete_branch(self)

func set_edit_mode(value: bool):
	$HBoxContainer/EditControl.visible = value


func _on_DownBtn_pressed():
	var ind = get_index()
	if (AppInstance.document["Branches"].size() > ind + 1):
		AppInstance.document["Branches"].remove(ind)
		AppInstance.document["Branches"].insert(ind + 1, _content)
		var next_cell = AppInstance.app_win.dialogs_list.get_child(ind + 1)
		next_cell.update_content(AppInstance.document["Branches"][ind + 1])
		update_content(AppInstance.document["Branches"][ind])
		AppInstance.app_win.update_branch_states()
		AppInstance.select_branch(null)
		AppInstance.select_branch(self)


func _on_UpBtn_pressed():
	var ind = get_index()
	if (ind > 0):
		AppInstance.document["Branches"].remove(ind)
		AppInstance.document["Branches"].insert(ind - 1, _content)
		var prev_cell = AppInstance.app_win.dialogs_list.get_child(ind - 1)
		prev_cell.update_content(AppInstance.document["Branches"][ind - 1])
		update_content(AppInstance.document["Branches"][ind])
		AppInstance.app_win.update_branch_states()
		AppInstance.select_branch(null)
		AppInstance.select_branch(self)


func _on_PhraseText_focus_exited():
	phrase_text.deselect()


func _on_NameText_focus_exited():
	name_text.deselect()
	if (old_name != "" && _content["Name"] != "" && old_name != _content["Name"]):
		AppInstance.rename_branch(old_name, _content["Name"])
