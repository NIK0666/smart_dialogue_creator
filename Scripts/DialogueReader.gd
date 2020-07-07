extends Node

class_name DialogueReader

signal change_phrase(phrase_text)
signal change_branches(branches_array)
signal change_speaker_id(speaker_id)

var public_config: Dictionary = {}
var current_dialog: Dictionary = {}
var current_branch: Dictionary = {}
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
# @dial_name - имя файла диалога
func open_dialog(dial_name):
	current_dialog = __load_json(dialogs_path + dial_name + ".json")
	if (current_dialog["autobranch"] && current_dialog["autobranch"] != ""):
		__change_current_branch(__find_branch(current_dialog["autobranch"]))
	else:
		answer_branches = __find_visible_branches()
		var branches_text: Array = []
		for branch in answer_branches:
			branches_text.append(branch["text"])
		emit_signal("change_branches", branches_text)


func set_public_config(config_name):
	public_config = __load_json(configs_path + config_name + ".config")


# Необходимо вызывть для переключения на следующую фразу диалога
# Если следующая фраза последняя, то:
#	- если стоит галка show_choice то показывается только список веток, указанных в show
#	- иначе показываются все видимые ветки
func next_phrase():
	phrase_index += 1
	var phrases: Array = current_branch["phrases"]
	if (phrase_index < phrases.size()):
		var phrase_dict: Dictionary = phrases[phrase_index]
		if (current_speaker_id != phrase_dict["npc"]):
			current_speaker_id = phrase_dict["npc"]
			emit_signal("change_speaker_id", current_speaker_id)
		emit_signal("change_phrase", phrase_dict["text"])
		
		if (phrases.size() - 1 == phrase_index):
			if (!current_branch["choice"]):
				answer_branches = __find_visible_branches()
			elif (answer_branches.size() == 1):
				return
			var branches_text: Array = []
			for branch in answer_branches:
				branches_text.append(branch["text"])
			emit_signal("change_branches", branches_text)
	elif (current_branch["choice"] && phrase_index == phrases.size() && answer_branches.size() == 1):
		__change_current_branch(answer_branches[0])


# Выбрать вариант ответа
# @index - выбирается по индексу в массиве предоставленных вариантов
func select_branch(index: int):
	__change_current_branch(answer_branches[index])


# Получить локальную или глобальную переменную
# @key - имя переменной
func get_var(key: String) -> Dictionary:
	var out_dict:Dictionary = __get_local_var(key)
	if out_dict.empty():
		out_dict = __get_public_var(key)
	return out_dict


# Получить имя персонажа по id
# Я бы не рекомендовал получать имя таким способом, если используется локализация
func get_character_name(id: String) -> String:
	for ch in public_config["characters"]:
		if ch["id"] == id:
			return ch["name"]
	return ""


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
		current_branch["hidden"] = true
	
	if (current_branch["choice"]):
		__set_choice_branches()
	else:
		for branch_name in current_branch["show"]:
			var br: Dictionary = __find_branch(branch_name)
			br["hidden"] = false
	
	for branch_name in current_branch["hide"]:
		var br: Dictionary = __find_branch(branch_name)
		br["hidden"] = true
	
	for var_dict in current_branch["vars"]:
		__change_var(var_dict)

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
		var success_conditions: bool = true
		for condition in br["if"]:
			if br["or_cond"]:
				success_conditions = __check_contition(condition)
				if success_conditions:
					break
			else:
				if !__check_contition(condition):
					success_conditions = false
					break
		if (success_conditions):
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
		if (dict["hidden"]):
			continue
		if (dict["if"].size() > 0):
			continue # if
		branches.append(dict)
	return branches

# Изменить значение переменной
# @var_dict - информация о изменяемой переменной и данные для изменения
func __change_var(var_dict: Dictionary):
	var found_var: Dictionary = get_var(var_dict["key"])
	if (found_var.empty()):
		print("Var is not found!")
		return

	if var_dict["op"] == "=":
		found_var["value"] = var_dict["value"]
	else:
		var curr_val: int = found_var["value"].to_int()
		var op_val: int = var_dict["value"].to_int()
		
		if var_dict["op"] == "+":
			curr_val = curr_val + op_val
		elif var_dict["op"] == "-":
			curr_val = curr_val - op_val
		elif var_dict["op"] == "*":
			curr_val = curr_val * op_val
		elif var_dict["op"] == "/":
			curr_val = curr_val / op_val
		found_var["value"] = str(curr_val)


# Получить локальную переменную
# @key - имя переменной
func __get_local_var(key: String) -> Dictionary:
	for local_var in current_dialog["variables"]:
		if local_var["key"] == key:
			return local_var
	return {}


# Получить публичную переменную
# @key - имя переменной
func __get_public_var(key: String) -> Dictionary:
	for public_var in public_config["variables"]:
		if public_var["key"] == key:
			return public_var
	return {}


# Проверка условия на выполнение
# @var_dict - информация о условии
# возвращает истину если условие выполнено
func __check_contition(var_dict: Dictionary) -> bool:
	var found_var: Dictionary = get_var(var_dict["key"])
	if (var_dict["op"] == "=="):
		if found_var["value"] == var_dict["value"]:
			return true
	elif (var_dict["op"] == "!="):
		if found_var["value"] != var_dict["value"]:
			return true
	else:
		var check_value: int = var_dict["value"].to_int()
		var curr_value: int = found_var["value"].to_int()
		
		if (var_dict["op"] == ">"):
			return curr_value > curr_value
		elif (var_dict["op"] == ">="):
			return curr_value >= curr_value
		elif (var_dict["op"] == "<"):
			return curr_value < curr_value
		elif (var_dict["op"] == "<="):
			return curr_value <= curr_value
	return false







