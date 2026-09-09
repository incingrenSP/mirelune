class_name StatComponent
extends Node

signal stats_changed

@export var entity_stats: EntityStats
@export var entity_skills: EntitySkills

var _cache: Dictionary = {}
var _dirty: bool = true

func _mark_dirty() -> void:
	_dirty = true
	stats_changed.emit()
	
func _recompute() -> void:
	_cache.clear()
	
	for stat_type in StatModifierEntry.StatType.values():
		var base: float = get_base_stat(stat_type)
		var flat_sum := 0.0
		var percent_additive_sum := 0.0
		var percent_of_current_sum := 0.0
		
		for skill in entity_skills:
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
		#var sub_total: float = base + flat_sum
		#sub_total += base * percent_additive_sum
		#var final_value: float = sub_total * (1.0 + percent_of_current_sum)
		
		# (base * multiplier) + flats
		var sub_total: float = base * percent_additive_sum
		sub_total += flat_sum
		var final_value: float = sub_total * (1.0 + percent_of_current_sum)
		
		_cache[stat_type] = final_value
	
	_dirty = false

func equip_skill(skill: SkillData) -> void:
	if skill == null:
		return
		
	if skill.category == SkillData.SkillCategory.ACTIVE:
		return
	
	if entity_skills.equipped_passive_skills.has(skill):
		return
		
	entity_skills.equipped_passive_skills.append(skill)
	_mark_dirty()
	
func unequip_skill(skill: SkillData) -> void:
	if entity_skills.has(skill):
		entity_skills.erase(skill)
		_mark_dirty()
	
func get_base_stat(stat: int) -> float:
	if not is_instance_valid(entity_stats):
		return 0.0
		
	match stat:
		StatModifierEntry.StatType.ATK: return entity_stats.atk
		StatModifierEntry.StatType.DEF: return entity_stats.def
		StatModifierEntry.StatType.ADR: return entity_stats.adr
		StatModifierEntry.StatType.SPD: return entity_stats.spd
		StatModifierEntry.StatType.MAX_HP: return entity_stats.max_hp
		StatModifierEntry.StatType.MAX_SP: return entity_stats.max_sp
		StatModifierEntry.StatType.HP_REGEN: return entity_stats.hp_regen_rate
		StatModifierEntry.StatType.SP_REGEN: return entity_stats.sp_regen_rate
		StatModifierEntry.StatType.XP_MULT: return entity_stats.xp_multiplier
		StatModifierEntry.StatType.CAST_SPEED: return entity_stats.cast_speed
	return 0.0
	
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
		
	for skill in entity_skills:
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
	
