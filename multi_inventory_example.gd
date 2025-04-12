extends Node2D

@onready var inventory1: Inventory = $PlayerInventory
@onready var inventory2: Inventory = $ChestInventory

func _ready():
	print(inventory1)
	print(inventory2)
	# Connect signals to track item transfers
	inventory1.item_transferred.connect(_on_item_transferred)
	inventory2.item_transferred.connect(_on_item_transferred)
	
	# Add some test items to both inventories
	inventory1.add_item("con_medkit", 3)
	inventory1.add_item("wep_AK47")
	inventory2.add_item("amm_boolet", 10)
	inventory2.add_item("wep_revolver")

func _on_item_transferred(item, from_inventory, to_inventory):
	print("Item '" + item.item_id + "' transferred from " + from_inventory.name + " to " + to_inventory.name)
	
	# You can perform additional actions here when items are transferred
	# For example, play a sound effect, update UI, etc.
