extends Node

class_name DialogueReader

signal change_phrase(phrase_text)
signal change_branches(branches_array)
signal change_speaker_id(speaker_id)
signal close_dialog()
signal extern_event(event_data)
signal anim_event(animation_name)

#var public_config: DialConfig
var current_dialog: Dialogue
var status_info: Dictionary
var public_variables: Dictionary
var current_branch: Dictionary = {}
var current_branch_phrases: Array = []
var answer_branches: Array = []
var phrase_index: int = -1
var current_speaker_id: String = ""
var dialogs_path: String = "res://dialogs/"
var configs_path: String = "res://dialogs/"


func set_paths(dial_path: String, config_path: String):
	if dial_path != "":
		self.dialogs_path = dial_path
	if config_path != "":
		self.configs_path = config_path


# Необходимо вызвать для запуска диалога. 
# @dial_data - данные диалога в json
func start_dialog(dial_data: Dialogue, status_info: Dictionary):
	if (dial_data == null):
		print("ERROR: Dialogue resource is not set!")
		return
	
	current_dialog = dial_data
	self.status_info = status_info
	if (status_info.empty()):
		_make_status_info()
	
	if (status_info["autobranch"] != ""):
		var branch: String = status_info["autobranch"]
		status_info["autobranch"] = ""
		__change_current_branch(__find_branch(branch))
		
	else:
		answer_branches = __find_visible_branches()
		var branches_text: Array = []
		for branch in answer_branches:
			branches_text.append(branch["text"])
		emit_signal("change_branches", branches_text)

func set_public_vars_info(public_variables: Dictionary):
	self.public_variables = public_variables


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
		status_info["variables"][key] = value
	elif (__get_public_var(key)):
		public_variables[key] = value
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

# Функция загрузки JSON файла с диска
# @path - путь к файлу
func __load_json(path: String):
	var file = File.new()
	file.open(path, file.READ)
	var content = file.get_as_text()
	file.close()
	
	var result_json = JSON.parse(content)
	if result_json.error == OK:
		return result_json.result
	else:
		return null 


# Прочитать выбранную ветку диалога
# Здесь же изменяются значения переменным, задается видимость связанным веткам
func __read_branch():
	phrase_index = -1
	current_speaker_id = ""
	if (current_branch["hide_self"]):
		status_info["hidden_branches"][current_branch["name"]] = true
	
	if (current_branch["change_started"] != ""):
		status_info["autobranch"] = current_branch["change_started"]
	
	__check_emit_event(false)
	
	for var_dict in current_branch["vars"]:
		__change_var(var_dict)
	
	if (current_branch["choice"]):
		__set_choice_branches()
	else:
		for branch_name in current_branch["show"]:
			status_info["hidden_branches"][branch_name] = false
	
	for branch_name in current_branch["hide"]:
		status_info["hidden_branches"][branch_name] = true
		
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
		if (status_info["hidden_branches"][dict["name"]]):
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
	if (status_info["variables"].has(key)):
		return status_info["variables"][key]
	return null


# Получить публичную переменную
# @key - имя переменной
func __get_public_var(key: String):
	if (public_variables.has(key)):
		return public_variables[key]
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

func _make_status_info():
	var hidden_branches:Dictionary = {}
	var variables: Dictionary = {}
	for branch in current_dialog.branches:
		hidden_branches[branch["name"]] = branch["hidden"]
	
	for variable in current_dialog.variables:
		variables[variable["key"]] = variable["value"]
	
	status_info["hidden_branches"] = hidden_branches
	status_info["variables"] = variables
	status_info["autobranch"] = current_dialog.autobranch
















