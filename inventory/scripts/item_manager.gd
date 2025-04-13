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
	
var _availableInventories: Array[Node] = []

func register_available_inventory(inv: Inventory) -> void:
	_availableInventories.append(inv)

func get_available_inventories() -> Array[Node]:
	return _availableInventories.duplicate()
