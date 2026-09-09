class_name EntitySkills
extends Resource

const MAX_ACTIVE_SLOTS := 3
const MAX_PASSIVE_SLOTS := 3

@export var equipped_active_skills: Array[String] = ["", "", ""]
@export var equipped_passive_skills: Array[String] = ["", "", ""]

@export var current_skill: String = ""

func get_equipped_active_skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	
	for id in equipped_active_skills:
		var skill: SkillData = SkillDatabase.get_skill(id)
		
		if is_instance_valid(skill):
			out.append(skill)
			
	return out

func get_equipped_passive_skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	
	for id in equipped_passive_skills:
		var skill: SkillData = SkillDatabase.get_skill(id)
		
		if is_instance_valid(skill):
			out.append(skill)
			
	return out

func get_current_skill() -> SkillData:
	return SkillDatabase.get_skill(current_skill)

func get_all_stat_modifier_skills() -> Array[SkillData]:
	return get_equipped_passive_skills()
