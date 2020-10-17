tool
extends Label

func set_content(content: Dictionary):
	var _text: String = "[EVENT: " + content["name"]
	if content.has("param"):
		_text = _text + " WITH PARAM: " + content["param"]
	self.text = _text + "]"
