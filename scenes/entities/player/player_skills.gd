class_name PlayerSkills
extends EntitySkills

@export var unlocked_active_slots: int = 1
@export var unlocked_passive_slots: int = 0
@export var core_unlocked: bool = false

@export var core_skill_id: String = ""

@export var player_unlocked_skills: Array[String] = []

func get_equipped_core_skill() -> SkillData:
	var skill: SkillData = SkillDatabase.get_skill(core_skill_id)
	return skill

func get_all_stat_modifier_skills() -> Array[SkillData]:
	var out: Array[SkillData] = get_equipped_passive_skills()
	out.append(get_equipped_core_skill())
	
	return out
