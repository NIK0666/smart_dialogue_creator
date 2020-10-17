tool
extends PopupBtn

export var is_compare: bool = true

func update_popup_list():
	if (is_compare):
		for item in AppInstance.compares:
			get_popup().add_item(item)
	else:
		for item in AppInstance.operators:
			get_popup().add_item(item)
