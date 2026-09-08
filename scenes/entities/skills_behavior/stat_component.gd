class_name StatComponent
extends Node

signal stats_changed

@export var base_stats: Dictionary = {}

var _equipped_skills: Array[SkillData] = []
var _cache: Dictionary = {}
var _dirty: bool = true

func _mark_dirty() -> void:
	_dirty = true
	stats_changed.emit()
	
func _recompute() -> void:
	_cache.clear()
	
	for stat_type in StatModifierEntry.StatType.values():
		var base: float = base_stats.get(stat_type, 0.0)
		var flat_sum := 0.0
		var percent_additive_sum := 0.0
		var percent_of_current_sum := 0.0
		
		for skill in _equipped_skills:
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
						
		var sub_total: float = base + flat_sum + (base * percent_additive_sum)
		var final_value: float = sub_total + (sub_total + percent_of_current_sum)
		_cache[stat_type] = final_value
	
	_dirty = false

func equip_skill(skill: SkillData) -> void:
	if skill == null or skill.category == SkillData.SkillCategory.ACTIVE:
		return
	
	if _equipped_skills.has(skill):
		return
		
	_equipped_skills.append(skill)
	_mark_dirty()
	
func unequip_skill(skill: SkillData) -> void:
	if _equipped_skills.has(skill):
		_equipped_skills.erase(skill)
		_mark_dirty()
	
func set_base_stat(stat: int, value: float) -> void:
	base_stats[stat] = value
	_mark_dirty()
	
func get_base_stat(stat: int) -> float:
	return base_stats.get(stat, 0.0)
	
func get_stat(stat: int) -> float:
	if _dirty:
		_recompute()
	return _cache.get(stat, base_stats.get(stat, 0.0))
	
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
	for skill in _equipped_skills:
		if skill.has_flag(flag):
			return true
			
	return false
	
