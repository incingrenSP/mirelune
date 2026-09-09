class_name EntitySkills
extends Resource

const MAX_ACTIVE_SLOTS := 3
const MAX_PASSIVE_SLOTS := 3

@export var equipped_active_skills: Array[String] = ["", "", ""]
@export var equipped_passive_skills: Array[String] = ["", "", ""]

@export var current_skill: String = ""
