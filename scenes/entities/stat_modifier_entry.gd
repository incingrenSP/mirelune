class_name StatModifierEntry
extends Resource

enum StatType {
	ATK,
	DEF,
	ADR,
	SPD,
	MAX_HP,
	MAX_SP,
	HP_REGEN,
	SP_REGEN,
	XP_MULT,
	CAST_SPEED
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
		StatType.SPD: return "spd"
		StatType.MAX_HP: return "max_hp"
		StatType.MAX_SP: return "max_sp"
		StatType.HP_REGEN: return "hp_regen"
		StatType.SP_REGEN: return "sp_regen"
		StatType.XP_MULT: return "xp_mult"
		StatType.CAST_SPEED: return "cast_speed"
	
	return ""
		
