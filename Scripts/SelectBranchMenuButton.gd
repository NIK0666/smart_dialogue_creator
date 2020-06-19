extends PopupBtn

func update_popup_list():
	for item in AppInstance.exist_branches:
		get_popup().add_item(item)
