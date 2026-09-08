class_name SkillBehaviorData
extends Resource

## Base type for per-attack-type skill data.
## Subclass for each of AttackType: SkillshotBehavior, SurehitBehavior, AoeBehavior.
## Left empty on purpose -> it exists so SkillData.behavior can hold any of the subtypes
## via a single polymorphic export slot.
