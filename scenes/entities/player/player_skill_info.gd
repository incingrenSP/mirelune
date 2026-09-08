class_name PlayerSkillInfo
extends Resource

const MAX_ACTIVE_SLOTS := 3
const MAX_PASSIVE_SLOTS := 3

@export var unlocked_active_slots: int = 1
@export var unlocked_passive_slots: int = 0
@export var core_unlocked: bool = false

@export var equipped_active_skills: Array[String] = ["", "", ""]
@export var equipped_passive_skills: Array[String] = ["", "", ""]
@export var core_skill_id: String = ""

@export var current_skill: String = ""
@export var player_unlocked_skills: Array[String] = []
