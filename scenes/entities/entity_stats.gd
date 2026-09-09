class_name EntityStats
extends Resource

@export var display_name: String = ""
@export var level: int = 1

@export var max_hp: float = 100.0
@export var max_sp: float = 50.0

@export var hp: float = 0.0
@export var sp: float = 0.0

@export var atk: int = 10
@export var def: int = 10
@export var adr: int = 10
@export var spd: int = 4

@export var hp_regen_rate: float = 0.0
@export var sp_regen_rate: float = 5.0
@export var xp_multiplier: float = 0.0
@export var cast_speed: float = 1.0

var max_cast: float = 1.0
var cast: float = 0.0
