class_name SkillShotBehavior
extends SkillBehaviorData

enum ShotShape {
	BEAM,		# neuvillete CA
	BARRAGE,	# kaisa Q
	BLAST,		# hwei QQ
	PIERCE		# sandrone CA beam/ clorinde special NAs
}

@export var shape: ShotShape = ShotShape.BLAST
@export var projectile_speed: float
@export var width: float
@export var barrage_count: int  = 1
@export var barrage_interval: float = 0.1
