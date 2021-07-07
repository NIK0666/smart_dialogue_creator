tool
extends Panel


# Declare member variables here. Examples:
var _content: Dictionary
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func update_content(content: Dictionary):
	_content = content
	
	# Upper panel
	$HBoxContainer/HiddenCheck.pressed = content["Hidden"]
	$HBoxContainer/ClosedCheck.pressed = content["Closed"]
	$HBoxContainer/HideSelfCheck.pressed = content["Hide_self"]
	$VBoxContainer2/Panel4/ChoiceCheckBox.pressed = content["Choice"]
	$VBoxContainer2/Panel3/OrCheckBox.pressed = content["Or_cond"]
	
	if (!content["Event"].empty()):
		$HBoxContainer/Control/SignalText.text = content["Event"]["Name"]
		$HBoxContainer/Control/EventOptionsBtn.disabled = (content["Event"]["Name"] == "")
	else:
		$HBoxContainer/Control/SignalText.text = ""
		$HBoxContainer/Control/EventOptionsBtn.disabled = true

	$VBoxContainer2/Panel2/ChangeStartedBtn.set_text(content["Change_started"])

	# Hide branches info
	var arr_len = content["Hide"].size() 
	for ind in range(0,  6):
		var item = $VBoxContainer2/Panel/VBoxContainer.get_child(ind)
		if (arr_len > ind):
			item.text = content["Hide"][ind]
			item.self_modulate.a = 1
		else:
			item.set_text("")
			item.self_modulate.a = 0.33
	
	# Show branches info
	arr_len = content["Show"].size() 
	for ind in range(0,  6):
		var item = $VBoxContainer2/Panel4/VBoxContainer.get_child(ind)
		if (arr_len > ind):
			item.text = content["Show"][ind]
			item.self_modulate.a = 1
		else:
			item.set_text("")
			item.self_modulate.a = 0.33
	
	# Vars info
	arr_len = content["Vars"].size() 
	for ind in range(0,  5):
		var item = $VBoxContainer2/Panel2/VBoxContainer2.get_child(ind)
		if (arr_len > ind):
			item.get_child(0).set_text(content["Vars"][ind]["Key"])
			item.get_child(1).text = content["Vars"][ind]["Op"]
			item.get_child(2).text = content["Vars"][ind]["Value"]
		else:
			item.get_child(0).set_text("")
			item.get_child(1).text = "="
			item.get_child(2).text = ""
	
	# If info
	arr_len = content["If"].size() 
	for ind in range(0,  5):
		var item = $VBoxContainer2/Panel3/VBoxContainer2.get_child(ind)
		if (arr_len > ind):
			item.get_child(0).set_text(content["If"][ind]["Key"])
			item.get_child(1).text = content["If"][ind]["Op"]
			item.get_child(2).text = content["If"][ind]["Value"]
		else:
			item.get_child(0).set_text("")
			item.get_child(1).text = "=="
			item.get_child(2).text = ""

func _on_HiddenCheck_toggled(button_pressed):
	_content["Hidden"] = button_pressed
	AppInstance.app_win.update_branch_states()


func _on_ClosedCheck_toggled(button_pressed):
	_content["Closed"] = button_pressed
	AppInstance.app_win.update_branch_states()

func _on_HideSelfCheck_toggled(button_pressed):
	_content["Hide_self"] = button_pressed

func _on_ChoiceCheckBox_toggled(button_pressed):
	_content["Choice"] = button_pressed
	
func _on_OrCheckBox_toggled(button_pressed):
	_content["Or_cond"] = button_pressed
	
func _on_SignalText_text_changed(new_text):
	if (new_text != ""):
		_content["Event"]["Name"] = new_text
		$HBoxContainer/Control/EventOptionsBtn.disabled = (new_text == "")
	else:
		_content["Event"] = {}
	


func _on_HideBranch_change_value():
	var arr: Array = []
	for item in $VBoxContainer2/Panel/VBoxContainer.get_children():
		if (item.get_text() != ""):
			arr.append(item.text)
	_content["Hide"] = arr
	AppInstance.app_win.update_branch_states()


func _on_ShowBranch_change_value():
	var arr: Array = []
	for item in $VBoxContainer2/Panel4/VBoxContainer.get_children():
		if (item.get_text() != ""):
			arr.append(item.text)
	_content["Show"] = arr
	AppInstance.app_win.update_branch_states()


func _on_Var_text_changed(new_text):
	save_vars_info()

func save_vars_info():
	var arr: Array = []
	var container = $VBoxContainer2/Panel2/VBoxContainer2
	for item in container.get_children():
		if (item.get_child(0).get_text() != ""):
			arr.append({"Key": item.get_child(0).get_text(), "Op": item.get_child(1).text, "Value": item.get_child(2).text})
	_content["Vars"] = arr

func _on_if_text_changed(new_text):
	save_if_info()

func save_if_info():
	var arr: Array = []
	for item in $VBoxContainer2/Panel3/VBoxContainer2.get_children():
		if (item.get_child(0).get_text() != ""):
			arr.append({"Key": item.get_child(0).get_text(), "Op": item.get_child(1).text, "Value": item.get_child(2).text})
	_content["If"] = arr

func _on_ChangeStartedBtn_change_value():
	_content["Change_started"] = $VBoxContainer2/Panel2/ChangeStartedBtn.get_text()

func _on_EventOptionsBtn_pressed():
	AppInstance.app_win.event_panel.show_with_content(_content["Event"])
