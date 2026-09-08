extends Node

var skills: Dictionary = {}

func _ready():
	_load_all_skills("res://skills/")
	
func _load_all_skills(path: String):
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("SkillDatabase: could not open $s" % path)
		return
		
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var skill: SkillData = load(path + file_name)
			skills[skill.id] = skill
			
		file_name = dir.get_next()
	dir.list_dir_end()
	
func get_skill(id: String):
	return skills.get(id, null)
