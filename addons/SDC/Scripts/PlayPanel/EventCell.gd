tool
extends Label

func set_content(content: Dictionary):
	var _text: String = "[EVENT: " + content["Name"]
	if content.has("Param"):
		_text = _text + " WITH PARAM: " + content["Param"]
	self.text = _text + "]"
