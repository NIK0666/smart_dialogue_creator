tool
extends EditorPlugin

var topi = load("res://addons/SDC/icon_mini.png")
var dock

func get_plugin_icon():
	return topi

func has_main_screen():
	return true

func get_plugin_name():
	return "Dialogue Editor"

func make_visible(visible: bool):
	if (visible == true):
		dock.show()
	elif (dock):
		dock.hide()

func _enter_tree():
	add_autoload_singleton("AppInstance", "res://addons/SDC/Scripts/Core/AppInstance.gd")
	
	dock = preload("res://addons/SDC/Main.tscn").instance()
	get_editor_interface().get_editor_viewport().add_child(dock)
	make_visible(false)
	
	add_custom_type("Dialogue", "Dialogue", preload("res://addons/SDC/Scripts/Core/Dialogue.gd"), preload("res://addons/SDC/icon_mini.png"))
	
	

func _exit_tree():
	remove_autoload_singleton("AppInstance")
	if  not dock:
		return
	dock.queue_free()
	dock = null
	remove_custom_type("Dialogue")
