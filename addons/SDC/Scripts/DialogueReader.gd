extends Node

class_name DialogueReader

signal change_phrase(phrase_text)
signal change_branches(branches_array)
signal change_speaker_id(speaker_id)
signal close_dialog()
signal extern_event(event_data)
signal custom_parameter_event(param_key, param_value)
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

var loc_id: String = ""
var is_use_loc: bool = false

# Необходимо вызвать для запуска диалога. 
# @dial_data - данные диалога в json
func start_dialog(dial_data: Dialogue, start_branch: String = ""):
	
	assert(dial_data != null && !dial_data.Branches.empty(), 
		"ERROR: Dialogue resource is not set!")
	
	current_dialog = dial_data
	update_info_progress_if_needed(dial_data)

	if (start_branch != ""):
		dial_progress["Auto"] = ""
		__change_current_branch(__find_branch(start_branch))
	elif (dial_progress["Auto"] != ""):
		var Autobranch: String = dial_progress["Auto"]
		dial_progress["Auto"] = ""
		__change_current_branch(__find_branch(Autobranch))
	else:
		answer_branches = __find_visible_branches()
		var branches_text: Array = []
		for branch in answer_branches:
			branches_text.append(__get_branch_text(branch))
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
		if (current_speaker_id != phrase_dict["Npc"]):
			current_speaker_id = phrase_dict["Npc"]
			emit_signal("change_speaker_id", current_speaker_id)
		
		if (phrase_dict["Anim"] != ""):
			emit_signal("anim_event", phrase_dict["Anim"])
		
		if (phrase_dict["Custom_params"]):
			if (phrase_dict["Custom_params"] as Dictionary).keys().size() > 0:
				for key in phrase_dict["Custom_params"].keys():
					emit_signal("custom_parameter_event", key, phrase_dict["Custom_params"][key])
		
		emit_signal("change_phrase", __get_phrase_text(phrase_dict))
		
		if (current_branch_phrases.size() - 1 == phrase_index):
			if (!current_branch["Choice"]):
				answer_branches = __find_visible_branches()
			elif (answer_branches.size() == 1):
				return false
			if (current_branch["Closed"]):
				return true
			var branches_text: Array = []
			for branch in answer_branches:
				branches_text.append(__get_branch_text(branch))
			__check_emit_event(true)
			emit_signal("change_branches", branches_text)
			return false
	elif (current_branch["Choice"] && phrase_index == current_branch_phrases.size() && answer_branches.size() == 1):
		__check_emit_event(true)
		__change_current_branch(answer_branches[0])
	elif (current_branch["Closed"] == true):
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
		char_vars[current_dialog.Character][key] = value
	elif (__get_public_var(key)):
		public_vars[key] = value
	else:
		print("ERROR: Variable " + key + " is not found!")


func sel_loc_id(new_loc_id: String):
	loc_id = new_loc_id
	is_use_loc = !(new_loc_id == "")


func __check_emit_event(end_branch: bool):
	if (current_branch["Event"].empty()):
		return
	
	var is_post: bool = current_branch["Event"].has("Post") && current_branch["Event"]["Post"]	
	if end_branch && is_post:
		emit_signal("extern_event", current_branch["Event"])
	elif !is_post && !end_branch:
		emit_signal("extern_event", current_branch["Event"])


# Прочитать выбранную ветку диалога
# Здесь же изменяются значения переменным, задается видимость связанным веткам
func __read_branch():
	phrase_index = -1
	current_speaker_id = ""
	if (current_branch["Hide_self"]):
		dial_progress["Hidden"][current_branch["Name"]] = true
	
	if (current_branch["Change_started"] != ""):
		dial_progress["Auto"] = current_branch["Change_started"]
	
	__check_emit_event(false)
	
	for var_dict in current_branch["Vars"]:
		__change_var(var_dict)
	
	if (current_branch["Choice"]):
		__set_choice_branches()
	else:
		for branch_name in current_branch["Show"]:
			dial_progress["Hidden"][branch_name] = false
	
	for branch_name in current_branch["Hide"]:
		dial_progress["Hidden"][branch_name] = true
		
	__prepare_phrases()


func __prepare_phrases():
	# Предварительно получу все фразы, проверив по условиям
	current_branch_phrases = []
	var random_phrases: Array = []
	var skip_else: bool = false	
	for phrase in current_branch["Phrases"]:
		if (skip_else):
			if (phrase["If"].has("Else")):
				skip_else = phrase["If"]["Else"]
			else:
				skip_else = false
			continue
		if (phrase["If"].empty()):
			if (phrase.has("Random") && phrase["Random"]):
				random_phrases.append(phrase)
				continue
			if !random_phrases.empty():
				current_branch_phrases.append(random_phrases[randi() % random_phrases.size()])
				random_phrases = []

			current_branch_phrases.append(phrase)
		else:
			if (__check_condition(phrase["If"])):
				current_branch_phrases.append(phrase)
				skip_else = phrase["If"]["Else"]
	
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


# Показать ветки диалога по окончанию всех фраз, если стоит галка choice 
func __set_choice_branches():
	answer_branches = []
	for branch_name in current_branch["Show"]:
		var br: Dictionary = __find_branch(branch_name)
		if (__check_conditions(br["If"], br["Or_cond"])):
			answer_branches.append(br)


# Поиск ветки диалога по имени ветки
func __find_branch(branch_name: String) -> Dictionary:
	for dict in current_dialog["Branches"]:
		if dict["Name"] == branch_name:
			return dict
	return {}

# Найти все видимые ветки диалога, которые к тому же доступны по условиям
func __find_visible_branches() -> Array:
	var Branches: Array = []
	for dict in current_dialog["Branches"]:
		if (dial_progress["Hidden"][dict["Name"]]):
			continue
		if (!__check_conditions(dict["If"], dict["Or_cond"])):
			continue
		Branches.append(dict)
	return Branches

# Изменить значение переменной
# @var_dict - информация о изменяемой переменной и данные для изменения
func __change_var(var_dict: Dictionary):
	var found_var = get_var(var_dict["Key"])
	if (found_var == null):
		print("Var is not found!")
		return

	if var_dict["Op"] == "=":
		set_var(var_dict["Key"], var_dict["Value"])
	else:
		var curr_val: int = found_var.to_int()
		var op_val: int = var_dict["Value"].to_int()
		
		if var_dict["Op"] == "+":
			curr_val = curr_val + op_val
		elif var_dict["Op"] == "-":
			curr_val = curr_val - op_val
		elif var_dict["Op"] == "*":
			curr_val = curr_val * op_val
		elif var_dict["Op"] == "/":
			curr_val = curr_val / op_val
		set_var(var_dict["Key"], str(curr_val))


# Получить локальную переменную
# @key - имя переменной
func __get_local_var(key: String):
	
	if (!char_vars.has(current_dialog.Character)):
		return null
	
	if (!char_vars[current_dialog.Character].has(key)):
		return null
	
	return char_vars[current_dialog.Character][key]


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
	var found_var = get_var(var_dict["Key"])
	if (var_dict["Op"] == "=="):
		if found_var == var_dict["Value"]:
			return true
	elif (var_dict["Op"] == "!="):
		if found_var != var_dict["Value"]:
			return true
	else:
		var check_value: int = var_dict["Value"].to_int()
		var curr_value: int = found_var.to_int()
		
		if (var_dict["Op"] == ">"):
			return curr_value > check_value
		elif (var_dict["Op"] == ">="):
			return curr_value >= check_value
		elif (var_dict["Op"] == "<"):
			return curr_value < check_value
		elif (var_dict["Op"] == "<="):
			return curr_value <= check_value
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


func __get_branch_text(_branch: Dictionary) -> String:
	if (is_use_loc):
		if (_branch.has("Loc")):
			var out = _branch["Loc"].get(loc_id)
			if out:
				return out
	return _branch["Text"]


func __get_phrase_text(_phrase: Dictionary) -> String:
	if (is_use_loc):
		if (_phrase.has("Loc")):
			var out = _phrase["Loc"].get(loc_id)
			if out:
				return out
	return _phrase["Text"]

func get_progress_info():
	return progress_dict

func set_progress_info(progress_dict: Dictionary):
	self.progress_dict = progress_dict
	public_vars = progress_dict["Public_vars"]

func make_progress_info(config: DialConfig) -> Dictionary:
	var new_dict: Dictionary = {"Public_vars": {}}
	for dict in config.Variables:
		new_dict["Public_vars"][dict["Key"]] = dict["Value"]
	new_dict["Dials"] = {}
	set_progress_info(new_dict)
	return new_dict


# Добавляет информацию о диалоге в прогресс
func update_info_progress_if_needed(dial_res: Dialogue):
	var rid_id = dial_res.get_instance_id()
	if !progress_dict["Dials"].has(rid_id):
		progress_dict["Dials"][rid_id] = {"Hidden": {}}
		progress_dict["Char_vars"] = {}
	
	for branch in dial_res.Branches:
		if !(progress_dict["Dials"][rid_id]["Hidden"].has(branch["Name"])):
			progress_dict["Dials"][rid_id]["Hidden"][branch["Name"]] = branch["Hidden"]
		if !(progress_dict["Dials"][rid_id].has("Auto")):
			progress_dict["Dials"][rid_id]["Auto"] = dial_res.Autobranch
	
	dial_progress = progress_dict["Dials"][rid_id]
	
	if dial_res.Character == "" && !dial_res.Variables.empty():
		print("ERROR: Character id is not set and Variables exists! Use public Variables!")
		char_vars = {}
	else:
		if !progress_dict["Char_vars"].has(dial_res.Character):
			progress_dict["Char_vars"][dial_res.Character] = {}
		
		for variable in current_dialog.Variables:
			if !(progress_dict["Char_vars"][dial_res.Character].has(variable["Key"])):
				progress_dict["Char_vars"][dial_res.Character][variable["Key"]] = variable["Value"]
		
		char_vars = progress_dict["Char_vars"]


func clear_dialog_progress(dial_res: Dialogue):
	if (progress_dict["Dials"].has(dial_res.get_rid().get_id())):
		(progress_dict["Dials"] as Dictionary).erase(dial_res.get_rid().get_id())

func clear_all_dialogs_progress():
	(progress_dict as Dictionary).erase("Dials")

func clear_char_vars_progress(char_id: String):
	if (progress_dict["Char_vars"].has(char_id)):
		progress_dict["Char_vars"].erase(char_id)

func clear_all_char_vars_progress():
	progress_dict["Char_vars"] = {}

func clear_all_public_vars_progress():
	progress_dict["Public_vars"] = {}
	public_vars = progress_dict["Public_vars"]
