class_name PlayerTriggerArea
extends Area3D

var nearby_interactables: Array[Interactable] = []

'''
the main purpose of this is to instead force interactables on player vicinity
instead of interactable vicinity.
say player interacts with a bulletin board
naturally, the bulletin board has larger collision box, but that doesn't mean
the player should be able to interact with it from 5m away.
so instead if the interaction depends on whether the bulletin instead is in
player's range, then it would overall look better

this can ultimately help with 3 different kinds of interactions:
	1. player directly interacts with the entity by clicking when in range
	2. entity enters and forces interaction when its in player range
	3. player enters a designated event area, triggering a event.
'''

func _ready() -> void:	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
func _on_area_entered(area: Area3D):	
	if area is Interactable:
		print(">>>>> INTERACTABLE ENTERED: ", area.name)
		
		if area not in nearby_interactables:
			nearby_interactables.append(area)
			
			print(">>>>> Added interactable. Count: ", nearby_interactables.size())
		
		else:
			print("Not an interactable")
	
func _on_area_exited(area: Area3D):
	print("====PLAYER_TRIGGER ON AREA EXITED===")
	if area is Interactable:
		if area in nearby_interactables:
			nearby_interactables.erase(area)
			
			print(">>>>> Removed interactable. Count: ", nearby_interactables.size())
			
