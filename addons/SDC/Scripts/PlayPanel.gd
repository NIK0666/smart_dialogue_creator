tool
extends Panel

var dial_reader: DialogueReader

var CharacterCell = preload("res://addons/SDC/Components/PlayPanel/CharacterCell.tscn")
var TextCell = preload("res://addons/SDC/Components/PlayPanel/TextCell.tscn")
var EventCell = preload("res://addons/SDC/Components/PlayPanel/EventCell.tscn")
var AnswerButton = preload("res://addons/SDC/Components/PlayPanel/AnswerButton.tscn")
var scroll_to_bottom: bool = false
var status_info: Dictionary

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
	var vars_info: Dictionary = {}
	for dict in AppInstance.config.variables:
		vars_info[dict["key"]] = dict["value"]
	
	dial_reader.set_public_vars_info(vars_info)

	dial_reader.connect("change_phrase", self, "_phrase_changed")
	dial_reader.connect("change_branches", self, "_change_branches")
	dial_reader.connect("change_speaker_id", self, "_change_speaker_id")
	dial_reader.connect("close_dialog", self, "_close_dialog")
	dial_reader.connect("extern_event", self, "_extern_event")
	dial_reader.connect("anim_event", self, "_anim_event")
	

	__play_dialog()
	
	
	
func _phrase_changed(phrase_text: String):
	var cell = TextCell.instance()
	cell.set_text(phrase_text)
	history_container.add_child(cell)
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

func get_character_name(id: String) -> String:
	for ch in AppInstance.config.characters:
		if ch["id"] == id:
			return ch["name"]
	return ""

func _change_speaker_id(speaker_id: String):
	var cell = CharacterCell.instance()
	cell.set_name(get_character_name(speaker_id))
	history_container.add_child(cell)

func _close_dialog():
	__clean_data()
	talk_btn.disabled = false
	print(status_info)

func _extern_event(event_data: Dictionary):
	var cell = EventCell.instance()
	cell.set_content(event_data)
	history_container.add_child(cell)

func _anim_event(anim_name: String):
	print(anim_name)

func __play_dialog():
	status_info = {}
	dial_reader.start_dialog(AppInstance.resource, status_info)


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
	dial_reader.start_dialog(AppInstance.resource, status_info)
	talk_btn.disabled = true
