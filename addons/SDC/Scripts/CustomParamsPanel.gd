tool
extends Panel

var _content: Dictionary
var ParamCell = preload("res://addons/SDC/Components/CustomParams/CustomParamCell.tscn")
onready var params_list: VBoxContainer = $ScrollContainer/VBoxContainer

func show_with_content(content: Dictionary):
	get_parent().visible = true
	self.visible = true
	_content = content
	load_data()

func load_data():
	for item in _content.keys():
		var cell = ParamCell.instance()
		cell.update_content(item, _content[item])
		params_list.add_child(cell)
		cell.connect("RemoveParam", self, "_on_remove_param")

func clean_data():
	for item in params_list.get_children():
		params_list.remove_child(item)

func _on_CloseBtn_pressed():
	get_parent().visible = false
	self.visible = false
	
	for item in params_list.get_children():
		if (item.get_value() != ""):
			_content[item.get_key()] = item.get_value()
		elif _content.has(item.get_key()):
			_content.erase(item.get_key())
			
	
	clean_data()

func _on_remove_param(key: String):
	_content.erase(key)
	print(_content)
