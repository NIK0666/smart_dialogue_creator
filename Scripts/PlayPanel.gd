extends Panel

var dial_reader: DialogueReader
var dial_data: Dictionary

var CharacterCell = preload("res://Components/PlayPanel/CharacterCell.tscn")
var TextCell = preload("res://Components/PlayPanel/TextCell.tscn")
var AnswerButton = preload("res://Components/PlayPanel/AnswerButton.tscn")
var scroll_to_bottom: bool = false

onready var history_container: VBoxContainer = $VBoxContainer/HistoryScroll/HistoryVBox
onready var history_scroll: ScrollContainer = $VBoxContainer/HistoryScroll
onready var answers_container: VBoxContainer = $VBoxContainer/AnswersScroll/AnswersVBox
onready var talk_btn: Button = $VBoxContainer/Panel/TalkBtn


func show():
	__clean_data()
	get_parent().visible = true
	talk_btn.disabled = true
	self.visible = true
	
	dial_reader = DialogueReader.new()
	dial_reader.public_config = AppInstance.config

	dial_reader.connect("change_phrase", self, "_phrase_changed")
	dial_reader.connect("change_branches", self, "_change_branches")
	dial_reader.connect("change_speaker_id", self, "_change_speaker_id")
	dial_reader.connect("close_dialog", self, "_close_dialog")
	
	

	__play_dialog()
	
	
	
func _phrase_changed(phrase_text: String):
	var cell = TextCell.instance()
	cell.set_text(phrase_text)
	history_container.add_child(cell)
	print(history_scroll.get_v_scrollbar().max_value)
	scroll_to_bottom = true

func _change_branches(branches_array: Array):
	for elem in answers_container.get_children():
		answers_container.remove_child(elem)
	
	if (branches_array.size() == 0):
		var btn = AnswerButton.instance()
		btn.set_text("(Далее)")
		answers_container.add_child(btn)
		btn.connect("select_answer", self, "__next_phrase")
	else:
		for elem in branches_array:
			var btn = AnswerButton.instance()
			btn.set_text(elem)
			answers_container.add_child(btn)
			btn.connect("select_answer", self, "__select_phrase")

func __clean_data():
	for elem in answers_container.get_children():
		answers_container.remove_child(elem)
	for elem in history_container.get_children():
		history_container.remove_child(elem)
	
	
func __next_phrase(id: int):
	dial_reader.next_phrase()

func __select_phrase(id: int):
	dial_reader.select_branch(id)

func _change_speaker_id(speaker_id: String):
	var cell = CharacterCell.instance()
	cell.set_name(dial_reader.get_character_name(speaker_id))
	history_container.add_child(cell)

func _close_dialog():
	__clean_data()
	talk_btn.disabled = false
	

func __play_dialog():
	var dial_path: String = AppInstance.app_win.document_path
	var arr: Array = dial_path.split("/")
	dial_path = ""
	for ind in range(0, arr.size() - 1):
		dial_path = dial_path + arr[ind] + "/"
	var dial_name: String = arr[arr.size() - 1].split(".")[0]
	
	dial_reader.set_paths(dial_path, "")
	dial_data = dial_reader.open_dial_file(dial_name)
	dial_reader.start_dialog(dial_data)

func _process(delta):
	if (scroll_to_bottom):
		if history_scroll.get_rect().size.y < history_scroll.get_v_scrollbar().max_value:
			history_scroll.scroll_vertical = history_scroll.get_v_scrollbar().max_value
		else:
			history_scroll.scroll_vertical = 0
		scroll_to_bottom = false


func _on_CloseBtn_pressed():
	get_parent().visible = false
	self.visible = false


func _on_TalkBtn_pressed():
	dial_reader.start_dialog(dial_data)
	talk_btn.disabled = true
