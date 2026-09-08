extends Resource
class_name SkillData

enum SkillCategory {
	ACTIVE,
	PASSIVE,
	CORE
}

enum AttackType {
	SKILLSHOT,
	SUREHIT,
	AOE
}

enum SkillFlag {
	DISABLE_NORMAL_ATTACK,	# increases specific stat but disables normal attack
	REDUCE_CAST_SPEED,		# makes casting skills take longer, instead deal more damage or get buffs
	INCREASE_CAST_SPEED,	# makes casting skill faster sacrificing damage or status infliction or debuff
	ONE_USE_SKILLS			# makes skills one time use but hugely amplifies damage
}

@export var id: String
@export var display_name: String
@export var description: String
@export var category: SkillCategory
@export var icon: Texture2D = null

# ACTIVE skill fields
@export_group("Active Skill Data")
@export var sp_cost: int
@export var damage_scaling: String = "ATK"
@export var damage_formula: String = ""
@export var attack_type: AttackType = AttackType.SKILLSHOT
@export var range_value: float = 2.0
@export var cast_speed: float = 1.0
@export var behavior: SkillBehaviorData = null
@export var applied_statuses: Array[StatusApplication] = []

# PASSIVE/CORE skill fields
@export_group("Passive/Core Skill Data")
@export var stat_modifiers: Array[StatModifierEntry] = []
@export var flags: Array[SkillFlag] = []

# Implement skill interest stuff after properly designing enemy/loot systems
#@export var skill_interest: float = 0.0

func calculate_damage(caster_stats: Dictionary, target_stats: Dictionary) -> float:
	var expr := Expression.new()
	var vars := []
	var vals := []
	
	for key in caster_stats.keys():
		vars.append("target_" + key)
		vars.append(target_stats[key])
		
	var err := expr.parse(damage_formula, PackedStringArray(vars))
	
	if err != OK:
		push_error("Bad formula in %s: %s" % [id, expr.get_error_text()])
		return 0.0
		
	var result = expr.execute(vals)
	if expr.has_execute_failed():
		push_error("Formula execution failed for %s" % id)
		
	return result

func has_flag(flag: SkillFlag) -> bool:
	return flags.has(flag)
