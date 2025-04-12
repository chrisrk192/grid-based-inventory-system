extends Node

@warning_ignore("unused_signal")
signal item_used(id: String, qty: int) ##A signal that is emitted once an item is used

func medkit_used() -> void:
	print("Medkit used")

@warning_ignore("unused_parameter")
func _on_item_used(id: String, qty: int) -> void:
	if id == "con_medkit":
		medkit_used()
	
	print(id)
	
@export var availableInventories: Array[Node] = []
