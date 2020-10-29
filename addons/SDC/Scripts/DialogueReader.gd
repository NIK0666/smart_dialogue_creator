extends Node

class_name DialogueReader

signal change_phrase(phrase_text)
signal change_branches(branches_array)
signal change_speaker_id(speaker_id)
signal close_dialog()
signal extern_event(event_data)
signal anim_event(animation_name)

var current_dialog: Dialogue
var progress_dict: Dictionary

var dial_progress: Dictionary
var char_vars: Dictionary
var public_vars: Dictionary

var current_branch: Dictionary = {}
var current_branch_phrases: Array = []
var answer_branches: Array = []
var phrase_index: int = -1
var current_speaker_id: String = ""


# Необходимо вызвать для запуска диалога. 
# @dial_data - данные диалога в json
func start_dialog(dial_data: Dialogue, start_branch: String = ""):
	if (dial_data == null):
		print("ERROR: Dialogue resource is not set!")
		return
	
	current_dialog = dial_data
	update_info_progress_if_needed(dial_data)
	print(dial_progress["auto"])
	if (start_branch != ""):
		dial_progress["auto"] = ""
		__change_current_branch(__find_branch(start_branch))
	elif (dial_progress["auto"] != ""):
		var autobranch: String = dial_progress["auto"]
		dial_progress["auto"] = ""
		__change_current_branch(__find_branch(autobranch))
	else:
		answer_branches = __find_visible_branches()
		var branches_text: Array = []
		for branch in answer_branches:
			branches_text.append(branch["text"])
		emit_signal("change_branches", branches_text)
	
	
# Необходимо вызывть для переключения на следующую фразу диалога
# Если следующая фраза последняя, то:
#	- если стоит галка show_choice то показывается только список веток, указанных в show
#	- иначе показываются все видимые ветки
func next_phrase() -> bool:
	if (current_branch.empty()):
		return false
	phrase_index += 1
	if (phrase_index < current_branch_phrases.size()):
		var phrase_dict: Dictionary = current_branch_phrases[phrase_index]
		if (current_speaker_id != phrase_dict["npc"]):
			current_speaker_id = phrase_dict["npc"]
			emit_signal("change_speaker_id", current_speaker_id)
		
		if (phrase_dict["anim"] != ""):
			emit_signal("anim_event", phrase_dict["anim"])
		
		emit_signal("change_phrase", phrase_dict["text"])
		
		if (current_branch_phrases.size() - 1 == phrase_index):
			if (!current_branch["choice"]):
				answer_branches = __find_visible_branches()
			elif (answer_branches.size() == 1):
				return false
			if (current_branch["closed"]):
				return true
			var branches_text: Array = []
			for branch in answer_branches:
				branches_text.append(branch["text"])
			__check_emit_event(true)
			emit_signal("change_branches", branches_text)
			return false
	elif (current_branch["choice"] && phrase_index == current_branch_phrases.size() && answer_branches.size() == 1):
		__check_emit_event(true)
		__change_current_branch(answer_branches[0])
	elif (current_branch["closed"] == true):
		__check_emit_event(true)
		emit_signal("close_dialog")
		
		phrase_index = -1
		current_branch = {}
		return false
	return true


# Выбрать вариант ответа
# @index - выбирается по индексу в массиве предоставленных вариантов
func select_branch(index: int):
	__change_current_branch(answer_branches[index])


# Получить локальную или глобальную переменную
# @key - имя переменной
func get_var(key: String):
	var out_var = __get_local_var(key)
	if out_var == null:
		out_var = __get_public_var(key)
	return out_var


func set_var(key: String, value):
	if (__get_local_var(key)):
		char_vars[key] = value
	elif (__get_public_var(key)):
		public_vars[key] = value
	else:
		print("ERROR: Variable " + key + " is not found!")


func __check_emit_event(end_branch: bool):
	if (current_branch["event"].empty()):
		return
	
	var is_post: bool = current_branch["event"].has("post") && current_branch["event"]["post"]	
	if end_branch && is_post:
		emit_signal("extern_event", current_branch["event"])
	elif !is_post && !end_branch:
		emit_signal("extern_event", current_branch["event"])


# Прочитать выбранную ветку диалога
# Здесь же изменяются значения переменным, задается видимость связанным веткам
func __read_branch():
	phrase_index = -1
	current_speaker_id = ""
	if (current_branch["hide_self"]):
		dial_progress["hidden"][current_branch["name"]] = true
	
	if (current_branch["change_started"] != ""):
		dial_progress["auto"] = current_branch["change_started"]
	
	__check_emit_event(false)
	
	for var_dict in current_branch["vars"]:
		__change_var(var_dict)
	
	if (current_branch["choice"]):
		__set_choice_branches()
	else:
		for branch_name in current_branch["show"]:
			dial_progress["hidden"][branch_name] = false
	
	for branch_name in current_branch["hide"]:
		dial_progress["hidden"][branch_name] = true
		
	__prepare_phrases()


func __prepare_phrases():
	# Предварительно получу все фразы, проверив по условиям
	current_branch_phrases = []
	var random_phrases: Array = []
	var skip_else: bool = false	
	for phrase in current_branch["phrases"]:
		if (skip_else):
			if (phrase["if"].has("else")):
				skip_else = phrase["if"]["else"]
			else:
				skip_else = false
			continue
		if (phrase["if"].empty()):
			if (phrase.has("random") && phrase["random"]):
				random_phrases.append(phrase)
				continue
			if !random_phrases.empty():
				current_branch_phrases.append(random_phrases[randi() % random_phrases.size()])
				random_phrases = []

			current_branch_phrases.append(phrase)
		else:
			if (__check_condition(phrase["if"])):
				current_branch_phrases.append(phrase)
				skip_else = phrase["if"]["else"]
	
	if !random_phrases.empty():
		current_branch_phrases.append(random_phrases[randi() % random_phrases.size()])
		random_phrases = []


# Переключить ветку диалога
# @new_branch - данные фетки диалога
func __change_current_branch(new_branch: Dictionary):
	current_branch = new_branch
	emit_signal("change_branches", [])
	__read_branch()
	next_phrase()


# Показать ветки диалога по окончанию всех фраз, если стоит галка chooce 
func __set_choice_branches():
	answer_branches = []
	for branch_name in current_branch["show"]:
		var br: Dictionary = __find_branch(branch_name)
		if (__check_conditions(br["if"], br["or_cond"])):
			answer_branches.append(br)


# Поиск ветки диалога по имени ветки
func __find_branch(branch_name: String) -> Dictionary:
	for dict in current_dialog["branches"]:
		if dict["name"] == branch_name:
			return dict
	return {}

# Найти все видимые ветки диалога, которые к тому же доступны по условиям
func __find_visible_branches() -> Array:
	var branches: Array = []
	for dict in current_dialog["branches"]:
		if (dial_progress["hidden"][dict["name"]]):
			continue
		if (!__check_conditions(dict["if"], dict["or_cond"])):
			continue
		branches.append(dict)
	return branches

# Изменить значение переменной
# @var_dict - информация о изменяемой переменной и данные для изменения
func __change_var(var_dict: Dictionary):
	var found_var = get_var(var_dict["key"])
	if (found_var == null):
		print("Var is not found!")
		return

	if var_dict["op"] == "=":
		set_var(var_dict["key"], var_dict["value"])
	else:
		var curr_val: int = found_var.to_int()
		var op_val: int = var_dict["value"].to_int()
		
		if var_dict["op"] == "+":
			curr_val = curr_val + op_val
		elif var_dict["op"] == "-":
			curr_val = curr_val - op_val
		elif var_dict["op"] == "*":
			curr_val = curr_val * op_val
		elif var_dict["op"] == "/":
			curr_val = curr_val / op_val
		set_var(var_dict["key"], str(curr_val))


# Получить локальную переменную
# @key - имя переменной
func __get_local_var(key: String):
	if (char_vars.has(key)):
		return char_vars[key]
	return null


# Получить публичную переменную
# @key - имя переменной
func __get_public_var(key: String):
	if (public_vars.has(key)):
		return public_vars[key]
	return null


# Проверка условия на выполнение
# @var_dict - информация о условии
# возвращает истину если условие выполнено
func __check_condition(var_dict: Dictionary) -> bool:
	var found_var = get_var(var_dict["key"])
	if (var_dict["op"] == "=="):
		if found_var == var_dict["value"]:
			return true
	elif (var_dict["op"] == "!="):
		if found_var != var_dict["value"]:
			return true
	else:
		var check_value: int = var_dict["value"].to_int()
		var curr_value: int = found_var.to_int()
		
		if (var_dict["op"] == ">"):
			return curr_value > curr_value
		elif (var_dict["op"] == ">="):
			return curr_value >= curr_value
		elif (var_dict["op"] == "<"):
			return curr_value < curr_value
		elif (var_dict["op"] == "<="):
			return curr_value <= curr_value
	return false

# Проверка списка условий
# @conditions_array - массив условий
# @or_cond - если исина то если хотя бы одно условие верно возвращаем истину,
#            иначе возвращаем истину огда верны все условия
func __check_conditions(conditions_array: Array, or_cond: bool) -> bool:
	if (conditions_array.empty()):
		return true
	var success_conditions: bool = true
	for condition in conditions_array:
		if or_cond:
			success_conditions = __check_condition(condition)
			if success_conditions:
				break
		else:
			if !__check_condition(condition):
				success_conditions = false
				break
	return success_conditions


func get_progress_info():
	return progress_dict

func set_progress_info(progress_dict: Dictionary):
	self.progress_dict = progress_dict
	public_vars = progress_dict["public_vars"]

func make_progress_info(config: DialConfig) -> Dictionary:
	var new_dict: Dictionary = {"public_vars": {}}
	for dict in config.variables:
		new_dict["public_vars"][dict["key"]] = dict["value"]
	new_dict["dials"] = {}
	set_progress_info(new_dict)
	return new_dict


# Добавляет информацию о диалоге в прогресс
func update_info_progress_if_needed(dial_res: Dialogue):
	var rid_id = dial_res.get_instance_id()
	if !progress_dict["dials"].has(rid_id):
		progress_dict["dials"][rid_id] = {"hidden": {}}
		progress_dict["char_vars"] = {}
	
	for branch in dial_res.branches:
		if !(progress_dict["dials"][rid_id]["hidden"].has(branch["name"])):
			progress_dict["dials"][rid_id]["hidden"][branch["name"]] = branch["hidden"]
		if !(progress_dict["dials"][rid_id].has("auto")):
			print("!!!")
			progress_dict["dials"][rid_id]["auto"] = dial_res.autobranch
	
	dial_progress = progress_dict["dials"][rid_id]
	
	if dial_res.character == "" && !dial_res.variables.empty():
		print("ERROR: Character id is not set and variables exists! Use public variables!")
		char_vars = {}
	else:
		if !progress_dict["char_vars"].has(dial_res.character):
			progress_dict["char_vars"][dial_res.character] = {}
		
		for variable in current_dialog.variables:
			if !(progress_dict["char_vars"][dial_res.character].has(variable["key"])):
				progress_dict["char_vars"][dial_res.character][variable["key"]] = variable["value"]
		
		char_vars = progress_dict["char_vars"]


func clear_dialog_progress(dial_res: Dialogue):
	if (progress_dict["dials"].has(dial_res.get_rid().get_id())):
		(progress_dict["dials"] as Dictionary).erase(dial_res.get_rid().get_id())

func clear_all_dialogs_progress():
	(progress_dict as Dictionary).erase("dials")

func clear_char_vars_progress(char_id: String):
	if (progress_dict["char_vars"].has(char_id)):
		progress_dict["char_vars"].erase(char_id)

func clear_all_char_vars_progress():
	progress_dict["char_vars"] = {}

func clear_all_public_vars_progress():
	progress_dict["public_vars"] = {}
	public_vars = progress_dict["public_vars"]
