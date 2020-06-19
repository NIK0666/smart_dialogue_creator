extends TextEdit

export var expand = true
export var min_line = 3
export var max_line = 6

var scroll_bar

var font = get_font("")
var line_spacing
var line_height
var line_count

class_name ExpandableTextEdit

func _ready():
	scroll_bar = _get_vscroll_bar()
	
	line_spacing = _get_line_spacing()
	line_height = font.get_height() + line_spacing
	line_count = _get_real_line_count()
	
	_update_height(line_count)



func _get_line_spacing():
	var spacing
	
	if get("custom_constants/line_spacing") != null:
		spacing =  get("custom_constants/line_spacing")
	elif theme != null:
		if theme.get("TextEdit/constants/line_spacing") != 0:
			spacing = theme.get("TextEdit/constants/line_spacing")
		else:
			spacing = 4
	else:
		spacing = 4
	
	return spacing


func _get_real_line_count():
	var line_count = get_line_count()
	var lines_to_add = 0
	var scroll_size = scroll_bar.rect_size.x - 2
	
	for i in line_count:
		var line = get_line(i)
		var width = font.get_string_size(line).x
		if width > rect_size.x - scroll_size:
			lines_to_add += int(width / (rect_size.x - scroll_size))
	
	return line_count + lines_to_add


func _get_vscroll_bar():
	for c in get_children():
		if c is VScrollBar:
			return c


func _update_height(count):
	if !expand:
		return
	
	var lines_to_show
	
	if count < min_line:
		lines_to_show = min_line
	elif count > max_line:
		lines_to_show = max_line
	else:
		lines_to_show = count
	
	rect_min_size.y = lines_to_show * line_height + line_spacing
	rect_size.y = rect_min_size.y
	print(rect_size.y)
	update()

func _on_TextEdit_text_changed():
	var new_line_count = _get_real_line_count()
	
	if line_count < new_line_count:
		_update_height(new_line_count)
		line_count = new_line_count
	elif line_count > new_line_count:
		_update_height(new_line_count)
		line_count = new_line_count
