class_name StatComponent
extends Node

signal stats_changed

var _cache: Dictionary = {}
var _dirty: bool = true

@export var entity_stats: EntityStats
@export var entity_skills: EntitySkills

func _mark_dirty() -> void:
	_dirty = true
	stats_changed.emit()
	
func _recompute() -> void:
	_cache.clear()
	
	if not is_instance_valid(entity_skills):
		_dirty = false
		return
		
	var modifier_skills: Array[SkillData] = []
	
	if is_instance_valid(entity_skills):
		modifier_skills = entity_skills.get_all_stat_modifier_skills()
	
	for stat_type in StatModifierEntry.StatType.values():
		var base: float = get_base_stat(stat_type)
		var flat_sum := 0.0
		var percent_additive_sum := 0.0
		var percent_of_current_sum := 0.0
		
		for skill in modifier_skills:
			if not is_instance_valid(skill):
				continue
				
			for mod in skill.stat_modifiers:
				if mod.stat != stat_type:
					continue
				
				match mod.modifier_type:
					StatModifierEntry.ModifierType.FLAT:
						flat_sum += mod.value
					StatModifierEntry.ModifierType.PERCENT_ADDITIVE:
						percent_additive_sum += mod.value
					StatModifierEntry.ModifierType.PERCENT_OF_CURRENT:
						percent_of_current_sum += mod.value
						
		# (base + flats) * multiplier
		var sub_total: float = base + flat_sum
		sub_total += base * percent_additive_sum
		var final_value: float = sub_total * (1.0 + percent_of_current_sum)
		
		_cache[stat_type] = final_value
	
	_dirty = false

func equip_skill(skill: SkillData) -> void:
	if skill == null:
		return
		
	if skill.category == SkillData.SkillCategory.ACTIVE:
		return
	
	if entity_skills.get_all_stat_modifier_skills().has(skill):
		return
		
	entity_skills.get_all_stat_modifier_skills().append(skill)
	_mark_dirty()
	
func get_base_stat(stat: int) -> float:
	var data: float = 0.0
	
	if not is_instance_valid(entity_stats):
		return 0.0
			
	match stat:
		StatModifierEntry.StatType.ATK: data = entity_stats.atk
		StatModifierEntry.StatType.DEF: data = entity_stats.def
		StatModifierEntry.StatType.ADR: data = entity_stats.adr
		StatModifierEntry.StatType.SPD: data = entity_stats.spd
		StatModifierEntry.StatType.MAX_HP: data = entity_stats.max_hp
		StatModifierEntry.StatType.MAX_SP: data = entity_stats.max_sp
		StatModifierEntry.StatType.HP_REGEN: data = entity_stats.hp_regen_rate
		StatModifierEntry.StatType.SP_REGEN: data = entity_stats.sp_regen_rate
		StatModifierEntry.StatType.XP_MULT: data = entity_stats.xp_multiplier
		StatModifierEntry.StatType.CAST_SPEED: data = entity_stats.cast_speed
		
	return data
	
func get_stat(stat: int) -> float:
	if _dirty:
		_recompute()
	
	return _cache.get(stat, get_base_stat(stat))
	
func get_stats_as_formula_dict() -> Dictionary:
	if _dirty:
		_recompute()
	
	var out := {}
	
	for stat_type in StatModifierEntry.StatType.values():
		var key: String = StatModifierEntry.to_key(stat_type)
		
		if not key.is_empty():
			out[key] = get_stat(stat_type)
				
	return out
	
func has_flag(flag: int) -> bool:
	if not is_instance_valid(entity_skills):
		return false
		
	for skill in entity_skills.get_all_stat_modifier_skills():
		if is_instance_valid(skill) and skill.has_flag(flag):
			return true
			
	return false
	
func set_current_hp(value: float) -> void:
	if not is_instance_valid(entity_stats):
		return
	entity_stats.hp = clamp(value, 0.0, get_stat(StatModifierEntry.StatType.MAX_HP))

func get_current_sp() -> float:
	return entity_stats.sp if is_instance_valid(entity_stats) else 0.0

func set_current_sp(value: float) -> void:
	if not is_instance_valid(entity_stats):
		return
	entity_stats.sp = clamp(value, 0.0, get_stat(StatModifierEntry.StatType.MAX_SP))
	
func get_equipped_active_skills() -> Array[SkillData]:
	return entity_skills.get_equipped_active_skills() if is_instance_valid(entity_skills) else []
	
func get_equipped_passive_skills() -> Array[SkillData]:
	return entity_skills.get_equipped_passive_skills() if is_instance_valid(entity_skills) else []
	
func get_current_skill() -> SkillData:
	return entity_skills.get_current_skill() if is_instance_valid(entity_skills) else null
