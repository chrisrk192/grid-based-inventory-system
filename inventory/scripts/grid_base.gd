#Grid-Based Inventory system by Hexadotz
class_name Inventory extends TextureRect

#NOTE: #if GridBase is a child of a container you need to use this to reference the container
#that control GridBBases's transform not doing so will cause the hover rect to be offseted
@export var onload: bool = false ## loads the items from the save file
@export var Save_file_path: String = "res://saved_data.dat"

@export_subgroup("Grid")
@export var cell_size: int = 32
@export_range(1, 100, 1) var grid_height: int = 8
@export_range(1, 100, 1) var grid_width: int = 8
@export var hover_texture: Texture2D 

@onready var itemBase: PackedScene = preload("res://inventory/item_base.tscn")
var hover_rect: TextureRect

var item_held: Item = null
var offset: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO
var item_last_position: Vector2i = Vector2i.ZERO

var SAVED_ITEMS: Array[Dictionary] = []

@warning_ignore("unused_signal")
signal focus_grid_moved() ##Emitted when the mosue moves inside the inventory
@warning_ignore("unused_signal")
signal item_rotated() ##Emitted when the item is rotated
@warning_ignore("unused_signal")
signal item_swapped() ##Emitted when two items swap each other's places
@warning_ignore("unused_signal")
signal item_transferred(item: Item, from_inventory: Inventory, to_inventory: Inventory) ##Emitted when an item is transferred between inventories
#--------------------------------------------------#
func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_TILE
	custom_minimum_size = Vector2i(cell_size * grid_height, cell_size * grid_width)
	
	add_to_group("grid_inventory")
	
	# create the hover rect at scene startup to make the inventory more compact
	var hover_child: TextureRect = TextureRect.new()
	hover_child.texture = hover_texture
	hover_child.size = Vector2i(cell_size, cell_size)
	add_child(hover_child)
	hover_rect = hover_child
	
	if onload:
		load_items()
	
	ItemManager.availableInventories.append(self)

func _physics_process(_delta: float) -> void:
	
	mouse_pos = get_global_mouse_position()
	_hover_mouse()
	
	if Input.is_action_just_pressed("mouse1"):
		if item_held == null:
			_grab()
	if Input.is_action_just_released("mouse1"):
		if item_held != null:
			_release()
	
	if item_held != null:
		item_held.global_position = mouse_pos + offset
		
		# Get the current inventory grid the mouse is over
		var current_grid = _get_grid_at_position(mouse_pos)
		
		if current_grid != null:
			# Use the current grid's hover rect for placement checking
			var zone: Rect2 = Rect2(current_grid.hover_rect.global_position, item_held.get_global_rect().size)
			if current_grid.area_is_clear(zone, [item_held]):
				item_held.shadow.color = item_held.VALID_SPOT
			else:
				# the shadow color will be orange if there is only one item in the zone otherwise it will be red 
				var items_count = current_grid.items_in_zone_with_item(item_held)
				item_held.shadow.color = item_held.SWITCH_SPOT if items_count == 1 else item_held.OCCUPIED_SPOT 
		else:
			# If not over any grid, show as invalid placement
			item_held.shadow.color = item_held.OCCUPIED_SPOT
		
		# rotate the item
		if Input.is_action_just_pressed("rotate"):
			item_held.rotate()

func _hover_mouse() -> void:
	# Get the grid the mouse is currently over
	var current_grid = _get_grid_at_position(mouse_pos)
	if current_grid != null:
		var resault_position: Vector2 = Vector2.ZERO
		var prev_position: Vector2 = current_grid.hover_rect.position
		
		# snaps the hover rectangle to the grid that is closest to the mouse
		var snaper: Vector2 = ((mouse_pos - current_grid.global_position) - (Vector2(current_grid.cell_size, current_grid.cell_size) / 2)) if item_held == null else (item_held.global_position - current_grid.global_position)
		resault_position = snaper.snapped(Vector2(current_grid.cell_size, current_grid.cell_size))
		
		current_grid.hover_rect.position = resault_position
		
		if resault_position != prev_position:
			current_grid.emit_signal("focus_grid_moved")

# Get the inventory grid at a given position
func _get_grid_at_position(pos: Vector2) -> Inventory:
	# Check if mouse is over this inventory
	if get_global_rect().has_point(pos):
		return self
	
	# Check if mouse is over any other inventory
	for inv in ItemManager.availableInventories:
		if inv.get_global_rect().has_point(pos):
			return inv
	
	return null

#---------------------item handeling----------------------#
##Adds and item using it's id, returns true if the item been added otherwise false
func add_item(itemId: String = "", quantity: int = 1) -> bool:
	# spawn the item in an empty place
	var rect: Rect2i = get_global_rect()
	var item_data: Dictionary = ItemsDB.get_item(itemId)
	# loop through evrey cell in the inventory
	for line in range(rect.position.y, rect.end.y, cell_size):
		for column in range(rect.position.x, rect.end.x, cell_size):
			
			var place_point: Vector2i = Vector2i(column, line) # the location we're going to place the item at
			var area: Rect2 = Rect2(Vector2i(place_point), Vector2i(item_data.grid_size * cell_size)) # construct a bounding box from the item id to use
			
			# if the item we're adding is stackable and is already in the inventory just add to the quantity
			if item_data.stackble:
				for itm in get_items():
					print(itm)
					if itm.item_id == itemId:
						itm.quantity += quantity
						return true
				
			
			if area_is_clear(area, [item_held]):
				var item_instance: Item = itemBase.instantiate()
				add_child(item_instance)
				item_instance.prep_item(itemId)
				item_instance.global_position = place_point
				
				return true # gtfo once done
	
	push_error("Could not place item, inventory full")
	return false

func save_items() -> void:
	SAVED_ITEMS.clear()
	
	for item: Item in get_items():
		# the data that's being saved, add new properties if you need to, just make sure they are also in 
		var save_data: Dictionary = {
			"id": item.item_id,
			"pos": item.position,
			"qty": item.quantity,
			"rotated": item.is_rotated
		}
		SAVED_ITEMS.append(save_data)
	print(SAVED_ITEMS)
	
	# save to the file after that's done
	ItemsDB.save_to_file(SAVED_ITEMS, Save_file_path)

func load_items() -> void:
	# get the items from the file
	SAVED_ITEMS = ItemsDB.load_from_file(Save_file_path)
	
	for item in SAVED_ITEMS:
		var item_instance: Item = itemBase.instantiate()
		add_child(item_instance)
		item_instance.prep_item(item["id"])
		
		item_instance.position = item["pos"]
		item_instance.quantity = item["qty"]
		
		if item["rotated"]:
			item_instance.rotate()

func _grab() -> void:
	# if we have an item already picked up, don't bother
	if item_held != null:
		return
	
	if not location_is_clear(mouse_pos) and get_global_rect().has_point(mouse_pos):
		for cell: Item in get_items():
			if cell.get_global_rect().has_point(mouse_pos):
				item_held = cell
				offset = cell.global_position - mouse_pos
				move_child(item_held, get_child_count()) # display the item on top of the other items
				item_last_position = cell.global_position

func _release() -> void:
	if item_held == null:
		return
	
	var target_grid = _get_grid_at_position(mouse_pos)
	print(target_grid)
	
	# If not over any grid, return the item to its original position
	if target_grid == null:
		item_held.global_position = item_last_position
		item_last_position = Vector2i.ZERO
		item_held = null
		return
	
	# If we're over a different grid than the item's parent, handle transfer
	if target_grid != self and item_held.get_parent() == self:
		var area: Rect2 = Rect2(target_grid.hover_rect.global_position, item_held.get_global_rect().size)
		
		# Check if we can stack this item with an existing one in the target grid
		if item_held.stackable:
			for itm in target_grid.get_items():
				if itm.item_id == item_held.item_id and itm.stackable:
					if itm.get_global_rect().intersects(area):
						# Stack the items
						itm.quantity += item_held.quantity
						# Remove the original item
						item_held.queue_free()
						item_held = null
						emit_signal("item_transferred", item_held, self, target_grid)
						return
		
		# Check if the area is clear in the target grid
		if target_grid.area_is_clear(area, []):
			transfer_item_to_grid(item_held, target_grid, area.position)
			return
		else:
			# Handle any item swapping in the target grid
			_swap_between_grids(target_grid)
			return
	
	# Original single grid behavior for when we're over the same grid
	var area: Rect2 = Rect2(hover_rect.global_position, item_held.get_global_rect().size)
	
	# for stackable item, go through every item in the inventory if the item we're releasing it on is the same type as the one
	# currently holding and is stackable then add it to the quantity
	for itm in get_items():
		if itm != item_held and itm.stackable:
			if itm.get_global_rect().intersects(area) and itm.item_id == item_held.item_id:
				itm.quantity += item_held.quantity
				# remove the item from the grid after adding its quantity
				item_held.queue_free()
				item_held = null
				return

	# if the items are different or cannot be stacked
	if not get_global_rect().has_point(mouse_pos) or not is_inside_rect(area): # if the placement is invalid
		item_held.global_position = item_last_position
		item_last_position = Vector2i.ZERO
		item_held = null
	else:
		if area_is_clear(area, [item_held]):
			item_held.global_position = hover_rect.global_position
			offset = Vector2.ZERO
			item_held = null
		else:
			_swap()

# Transfer an item from one grid to another
func transfer_item_to_grid(item: Item, target_grid: Inventory, position: Vector2) -> void:
	# Remove from current parent
	remove_child(item)
	
	# Add to new parent
	target_grid.add_child(item)
	
	# Update position
	item.global_position = position
	
	# Clear held item reference
	item_held = null
	offset = Vector2.ZERO
	
	# Update grid reference in the item
	item.grid_map = target_grid
	
	# Emit signal
	emit_signal("item_transferred", item, self, target_grid)

# Handle swapping items between grids
func _swap_between_grids(target_grid: Inventory) -> void:
	var occupied: Array = []
	for cell: Item in target_grid.get_items():
		if cell.get_global_rect().intersects(Rect2(target_grid.hover_rect.global_position, item_held.get_global_rect().size)):
			occupied.append(cell)
	
	# If there's exactly one item in the way, we can swap
	if occupied.size() == 1:
		var target_item = occupied[0]
		var target_pos = target_grid.hover_rect.global_position
		var original_pos = item_last_position
		
		# Store references before we move anything
		var original_item = item_held
		
		# Move the item from target grid to this grid
		target_grid.remove_child(target_item)
		add_child(target_item)
		target_item.global_position = original_pos
		target_item.grid_map = self
		
		# Move our item to the target grid
		remove_child(original_item)
		target_grid.add_child(original_item)
		original_item.global_position = target_pos
		original_item.grid_map = target_grid
		
		# Clear held item reference
		item_held = null
		offset = Vector2.ZERO
		
		# Emit signals
		emit_signal("item_transferred", original_item, self, target_grid)
		target_grid.emit_signal("item_transferred", target_item, target_grid, self)
	else:
		# If swap can't happen, return to original position
		item_held.global_position = item_last_position
		item_last_position = Vector2i.ZERO
		item_held = null

func _swap() -> void:
	var occupied: Array = []
	for cell: Item in get_items():
		if cell == item_held:
			continue
		if cell.get_global_rect().intersects(item_held.get_global_rect()):
			occupied.append(cell)
	
	var zone: Rect2 = Rect2(occupied[0].global_position, item_held.size)
	if occupied.size() != 1 or not area_is_clear(zone, [item_held, occupied[0]]):
		item_held.global_position = item_last_position
		item_last_position = Vector2i.ZERO
		item_held = null
		return
	
	item_held.global_position = hover_rect.global_position
	item_held = occupied[0]
	
	move_child(item_held, get_child_count())
	emit_signal("item_swapped")

#---------------------------------------------------------#
##Returns the amount of items that are on top of the current held item
func items_in_zone() -> int:
	var count: int = 0
	for cell: Item in get_items():
		if cell == item_held:
			continue
		if cell.get_global_rect().intersects(item_held.get_global_rect()):
			count += 1
	
	return count

##Returns the amount of items that intersect with the given item
func items_in_zone_with_item(item: Item) -> int:
	var count: int = 0
	for cell: Item in get_items():
		if cell.get_global_rect().intersects(item.get_global_rect()):
			count += 1
	
	return count

##Checks if the area we're placing the item at isvalid (not outside the grid or on top another item)
func area_is_clear(zone: Rect2, execlude: Array) -> bool:
	# check if it's on top of another item
	for cell: Item in get_items():
		if cell not in execlude:
			if cell.get_global_rect().intersects(zone):
				return false
	
	return is_inside_rect(zone)

##Checks if the given zone if fully inside
func is_inside_rect(zone: Rect2) -> bool:
	# if the top left and the bottom right corners are inside the zone, then it's valid otherwise it's not valid
	if not get_global_rect().has_point(zone.position + Vector2(1, 1)) or not get_global_rect().has_point(zone.end - Vector2(1,1)):
		return false
	return true

##Checks if the position given is clear or not
func location_is_clear(pos: Vector2) -> bool:
	for cell: Item in get_items():
		if cell != item_held:
			if cell.get_global_rect().has_point(pos):
				return false
	return true

##Returns a list of all the items that are in the inventory, NOTE: the reason why we use the slice is because we don't want the
##hover rect to be counted as an item
func get_items() -> Array:
	return get_children().slice(1, get_children().size())
