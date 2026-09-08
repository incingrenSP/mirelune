class_name StatusEffectData
extends Resource

enum StatusType {
	BUFF,		# increase stat
	DEBUFF,		# decrease stat
	DOT,		# damage over time
	HOT,		# heal over time
	CC			# crowd-control
}

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var status_type: StatusType

@export var default_duration: float = 5.0
@export var tick_interval: float = 1.0
@export var tick_damage_formula: String = ""
@export var stackable: bool = false
@export var max_stacks: int = 1

@export var resistance_category: String = ""
