extends PopupBtn

func _ready():
	if (placeholder == ""):
		placeholder = "none_branch"
	._ready()

func update_popup_list():
	for item in AppInstance.exist_branches:
		get_popup().add_item(item)
