class_name PlayerStats
extends Resource

@export var player_name: String = "Player"
@export var player_level: int = 1

@export var max_hp: float = 100.0
@export var max_sp: float = 50.0
@export var max_xp: int = 500

@export var hp: float = 0.0
@export var sp: float = 0.0
@export var xp: int = 0

@export var atk: int = 10
@export var def: int = 10
@export var adr: int = 10
@export var spd: int = 4

@export var hp_regen_rate: float = 0.0
@export var sp_regen_rate: float = 5.0
@export var xp_multiplier: float = 0.0
@export var cast_time: float = 3.0
