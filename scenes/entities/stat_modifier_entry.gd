class_name StatModifierEntry
extends Resource

enum StatType {
	ATK,			# flat or % modifiers
	DEF,
	ADR,
	HP_REGEN,		# flat modifiers
	SP_REGEN,
	XP_MULT,		# % modifiers
	CAST_SPEED		# % modifiers
}

enum ModifierType {
	FLAT,
	PERCENT_ADDITIVE,
	PERCENT_OF_CURRENT
}

@export var stat: StatType
@export var modifier_type: ModifierType = ModifierType.FLAT
@export var value: float = 0.0

static func to_key(stat: StatType) -> String:
	match stat:
		StatType.ATK: return "atk"
		StatType.DEF: return "def"
		StatType.ADR: return "adr"
		StatType.HP_REGEN: return "hp_regen_rate"
		StatType.SP_REGEN: return "sp_regen_rate"
		StatType.XP_MULT: return "xp_multiplier"
		StatType.CAST_SPEED: return "cast_time_reduction"
	
	return ""
		
