extends ColorRect

class_name BranchCell

onready var name_text:LineEdit = $HBoxContainer/NameText
onready var phrase_text:LineEdit = $HBoxContainer/PhraseText

var _content: Dictionary

func _ready():
	set_state("Default")

func update_content(content: Dictionary):
	_content = content
	$HBoxContainer/NameText.text = _content["name"]
	if (_content.has("phrase")):
		$HBoxContainer/PhraseText.text = _content["phrase"]


func _on_Button_pressed():
	pass
	# AppInstance.request_service(_content["Source"]["Text"])


func _on_PhraseText_text_changed(new_text):
	_content["phrase"] = new_text

func _on_NameText_text_changed(new_text):
	_content["name"] = new_text
	AppInstance.update_branches()


func _on_NameText_focus_entered():
	AppInstance.select_branch(self)
	
func set_state(state_name: String):
	self.color = AppInstance.colors[state_name]
	if (!_content.empty() && _content["closed"]):
		$HBoxContainer/NameText.set("custom_colors/font_color", AppInstance.colors["Close"])
	elif (!_content.empty() && _content["hidden"]):
		$HBoxContainer/NameText.set("custom_colors/font_color", AppInstance.colors["Hidden"])
	else:
		$HBoxContainer/NameText.set("custom_colors/font_color", Color("ffffff"))

func get_content() -> Dictionary:
	return _content


func _on_DelBtn_pressed():
	AppInstance.delete_branch(self)
