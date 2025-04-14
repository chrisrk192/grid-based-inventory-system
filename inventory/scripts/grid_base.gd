class_name Inventory extends TextureRect

@export var onload: bool = false ## loads the items from the save file
@export var Save_file_path: String = "res://saved_data.dat"

@export_subgroup("Grid")
@export var cell_size: int = 32
@export_range(1, 100, 1) var grid_height: int = 8
@export_range(1, 100, 1) var grid_width: int = 8
@export var hover_texture: Texture2D 

@onready var itemBase: PackedScene = preload("res://inventory/item_base.tscn")
var hover_rect: TextureRect

var item_held: InventoryItem = null
var offset: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO
var item_last_position: Vector2i = Vector2i.ZERO

var SAVED_ITEMS: Array[Dictionary] = []

@warning_ignore("unused_signal")
signal focus_grid_moved() ##Emitted when the mouse moves inside the inventory
@warning_ignore("unused_signal")
signal item_rotated() ##Emitted when the item is rotated
@warning_ignore("unused_signal")
signal item_swapped() ##Emitted when two items swap each other's places
@warning_ignore("unused_signal")
signal item_transferred(item: InventoryItem, from_inventory: Inventory, to_inventory: Inventory) ##Emitted when an item is transferred between inventories

#--------------------------------------------------#
func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_TILE
	custom_minimum_size = Vector2i(cell_size * grid_width, cell_size * grid_height)
	
	add_to_group("grid_inventory")
	
	# Create the hover rect
	var hover_child: TextureRect = TextureRect.new()
	hover_child.texture = hover_texture
	hover_child.size = Vector2i(cell_size, cell_size)
	add_child(hover_child)
	hover_rect = hover_child
	
	if onload:
		load_items()
	
	ItemManager.register_available_inventory(self)

func _notification(what):
	if (what == NOTIFICATION_PREDELETE):
		ItemManager._availableInventories.erase(self)

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
		if(current_grid): 
			print(item_held.global_position, " maps to ", current_grid.world_to_grid(item_held.global_position))
		
		#if current_grid != null and current_grid != item_held.grid_map:
			#item_held.grid_map = current_grid
			#item_held.recalculate_size()
		
		#if current_grid != null:
			## Check if the current position is valid
			#var test_position = current_grid.hover_rect.global_position
			#var cells = item_held.get_occupied_cells(test_position)
			#
			#if current_grid.all_cells_are_clear(cells, [item_held]):
				## Set all shadow cells to valid color
				#for shadow_rect in item_held.shadow_rects:
					#shadow_rect.color = item_held.VALID_SPOT
			#else:
				#var intersect_count = current_grid.count_intersecting_items(cells, item_held)
				#var color = item_held.SWITCH_SPOT if intersect_count == 1 else item_held.OCCUPIED_SPOT
				#
				## Set all shadow cells to appropriate color
				#for shadow_rect in item_held.shadow_rects:
					#shadow_rect.color = color
		#else:
			## Set all shadow cells to occupied color
			#for shadow_rect in item_held.shadow_rects:
				#shadow_rect.color = item_held.OCCUPIED_SPOT
		
		# Rotate the item
		if Input.is_action_just_pressed("rotate"):
			item_held.rotate()
		
		if(current_grid != null):
			current_grid.offset = self.offset

	if(item_held == null and Input.is_action_just_pressed("mouse2")):
		var hovered_item = _get_item_at_mouse_pos()
		if(hovered_item != null): hovered_item.show_menu()
		
# Convert world position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - global_position
	return Vector2i(int(local_pos.x / cell_size), int(local_pos.y / cell_size))

# Convert grid coordinates to world position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return global_position + Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)

func _hover_mouse() -> void:
	var current_grid = _get_grid_at_position(mouse_pos)
	if current_grid != null:
		var result_position: Vector2 = Vector2.ZERO
		var prev_position: Vector2 = current_grid.hover_rect.position
		
		# Snap the hover rectangle to the grid
		var snap_target
		if item_held == null:
			snap_target = (mouse_pos - current_grid.global_position)
		else:
			snap_target = (item_held.global_position - current_grid.global_position)
		result_position = (snap_target - Vector2(current_grid.cell_size/2, current_grid.cell_size/2)).snappedf(current_grid.cell_size)

		current_grid.hover_rect.position = result_position
		
		if result_position != prev_position:
			current_grid.emit_signal("focus_grid_moved")
			

# Get the inventory grid at a given position
func _get_grid_at_position(pos: Vector2) -> Inventory:
	if get_global_rect().has_point(pos):
		return self
		
	for inv in ItemManager.get_available_inventories():
		if inv != null and inv.get_global_rect().has_point(pos):
			return inv
	
	return null

#---------------------item handling----------------------#
##Adds an item using its id, returns true if the item was added
func add_item(itemId: String = "", quantity: int = 1) -> bool:
	var item_data: Item = ItemsDB.get_item(itemId)
	
	# Check for stackable items
	if item_data.stackable:
		for itm in get_items():
			if itm.item_stats.item_id == item_data.item_id:
				itm.quantity += quantity
				return true
	
	# Create a new item instance to test placements
	var item_instance: InventoryItem = itemBase.instantiate()
	add_child(item_instance)
	item_instance.prep_item(itemId)
	
	# Try to find a valid position for the item
	var valid_pos = find_valid_position(item_instance)
	
	if valid_pos != null:
		item_instance.global_position = valid_pos
		return true
	else:
		# No valid position found, clean up and return false
		item_instance.queue_free()
		push_error("Could not place item, inventory full")
		return false

# Find a valid position for an item in the inventory
func find_valid_position(item: InventoryItem):
	var grid_rect = get_global_rect()
	
	# Try each grid cell as a potential starting position
	for y in range(0, grid_height):
		for x in range(0, grid_width):
			var test_pos = grid_to_world(Vector2i(x, y))
			var occupied_cells = item.get_occupied_cells(test_pos)
			
			if all_cells_are_clear(occupied_cells, [item]):
				return test_pos
	
	return null

# Check if all the cells in an array are clear (not occupied by other items)
func all_cells_are_clear(cells: Array, exclude_items: Array = []) -> bool:
	# Check if all cells are within the grid bounds
	for cell_pos in cells:
		var grid_pos = world_to_grid(cell_pos)
		
		if grid_pos.x < 0 or grid_pos.x >= grid_width or grid_pos.y < 0 or grid_pos.y >= grid_height:
			print("Outside of grid bounds")
			return false
	
	# Check if any cells overlap with existing items
	for cell_pos in cells:
		for item in get_items():
			if item in exclude_items:
				continue
				
			var item_cells = item.get_occupied_cells()
			
			for item_cell in item_cells:
				if world_to_grid(cell_pos) == world_to_grid(item_cell):
					print("Overlap on cell : ",world_to_grid(cell_pos), " at ", cell_pos)
					return false
	
	return true

# Count how many items intersect with the given cells
func count_intersecting_items(cells: Array, exclude_item: InventoryItem = null) -> int:
	var intersecting_items = []
	
	for item in get_items():
		if item == exclude_item:
			continue
			
		var item_cells = item.get_occupied_cells()
		var has_intersection = false
		
		for cell in cells:
			for item_cell in item_cells:
				if world_to_grid(cell) == world_to_grid(item_cell):
					has_intersection = true
					break
			
			if has_intersection:
				if not item in intersecting_items:
					intersecting_items.append(item)
				break
	
	return intersecting_items.size()

func save_items() -> void:
	SAVED_ITEMS.clear()
	
	for item: InventoryItem in get_items():
		var save_data: Dictionary = {
			"id": item.item_stats.name,
			"pos": item.position,
			"qty": item.quantity,
			"rotated": item.is_rotated,
			"grid_shape": item.grid_shape
		}
		SAVED_ITEMS.append(save_data)
	
	ItemsDB.save_to_file(SAVED_ITEMS, Save_file_path)

func load_items() -> void:
	SAVED_ITEMS = ItemsDB.load_from_file(Save_file_path)
	
	for item_data in SAVED_ITEMS:
		var item_instance: InventoryItem = itemBase.instantiate()
		add_child(item_instance)
		
		item_instance.prep_item(item_data["id"])
		item_instance.position = item_data["pos"]
		item_instance.quantity = item_data["qty"]
		
		if "grid_shape" in item_data:
			item_instance.grid_shape = item_data["grid_shape"]
		
		if item_data["rotated"]:
			item_instance.rotate()

func _get_item_at_mouse_pos() -> InventoryItem:
	#this is a bad implementation
	if get_global_rect().has_point(mouse_pos):
		for item: InventoryItem in get_items():
			var occupied_cells = item.get_occupied_cells()
			var current_grid = self
			var mouse_cell_pos = ((mouse_pos - current_grid.global_position) - Vector2(current_grid.cell_size/2, current_grid.cell_size/2)).snappedf(current_grid.cell_size)

			for cell_pos in occupied_cells:
				#print(cell_pos, " compared to ", mouse_cell_pos)
				if cell_pos.distance_to(mouse_cell_pos + current_grid.global_position) < cell_size / 2:
					return item
	return null

func _grab() -> void:
	if item_held != null:
		return
	var hovered_item = _get_item_at_mouse_pos()
	if(hovered_item != null):
		item_held = hovered_item
		offset = hovered_item.global_position - mouse_pos
		move_child(item_held, get_child_count())  # Move to top of display hierarchy
		item_last_position = hovered_item.global_position

func _release() -> void:
	if item_held == null:
		print("Holding nothing")
		return
	
	var target_grid = _get_grid_at_position(mouse_pos)
	
	# If not over any grid, return the item to its original position
	if target_grid == null:
		item_held.global_position = item_last_position
		item_last_position = Vector2i.ZERO
		item_held = null
		print("Target Grid is null, returning")
		return
	
	# Handle transfer between inventories
	if target_grid != self and item_held.get_parent() == self:
		handle_transfer_to_other_grid(target_grid)
		print("handled transfer to other grid")
		return
	
	# Handle placement within the same inventory
	var partial_cell_offset = Vector2(floori(target_grid.global_position.x) % target_grid.cell_size, floori(target_grid.global_position.y) % target_grid.cell_size)#hover_rect.global_position
	var test_position =  grid_to_world(world_to_grid(item_held.global_position))#item_held.global_position.snappedf(target_grid.cell_size) + partial_cell_offset
	var occupied_cells = item_held.get_occupied_cells(test_position)
	
	# Check for stackable items
	if item_held.item_stats.stackable:
		for item in get_items():
			if item != item_held and item.item_stats.item_id == item_held.item_stats.item_id and item.item_stats.stackable:
				var item_cells = item.get_occupied_cells()
				var would_overlap = false
				
				for cell in occupied_cells:
					for item_cell in item_cells:
						if world_to_grid(cell) == world_to_grid(item_cell):
							would_overlap = true
							break
					
					if would_overlap:
						break
				
				if would_overlap:
					# Stack the items
					item.quantity += item_held.quantity
					item_held.queue_free()
					item_held = null
					print("Stacking Items")
					return
	
	# Check if the placement area is clear
	if all_cells_are_clear(occupied_cells, [item_held]):
		print("all_cells_are_clear", item_held.global_position, 
				" getting set to ", test_position, " aka cell: ", world_to_grid(item_held.global_position),
				" to cell ", world_to_grid(test_position)
				)
		item_held.global_position = grid_to_world(world_to_grid(item_held.global_position))# test_position# + partial_cell_offset
		offset = Vector2.ZERO
		item_held = null
	else:
		item_held.global_position = item_last_position
		offset = Vector2.ZERO
		item_held = null
		print("all_cells_are NOT clear:", occupied_cells )

# Handle transferring an item to another inventory grid
func handle_transfer_to_other_grid(target_grid: Inventory) -> void:
	var partial_cell_offset = Vector2(floori(target_grid.global_position.x) % target_grid.cell_size, floori(target_grid.global_position.y) % target_grid.cell_size)#hover_rect.global_position
	var test_position = grid_to_world(world_to_grid(item_held.global_position)) #item_held.global_position.snappedf(target_grid.cell_size) + partial_cell_offset
	var occupied_cells = item_held.get_occupied_cells(test_position)
	
	# Check if the item is stackable and can be merged with an existing item
	if item_held.item_stats.stackable:
		for target_item in target_grid.get_items():
			if target_item.item_stats.item_id == item_held.item_stats.item_id and target_item.item_stats.stackable:
				# Check if they would occupy the same space
				var target_cells = target_item.get_occupied_cells()
				var would_overlap = false
				
				for cell in occupied_cells:
					for target_cell in target_cells:
						if target_grid.world_to_grid(cell) == target_grid.world_to_grid(target_cell):
							would_overlap = true
							break
					
					if would_overlap:
						break
				
				if would_overlap:
					# Stack the items
					target_item.quantity += item_held.quantity
					item_held.queue_free()
					item_held = null
					emit_signal("item_transferred", null, self, target_grid)
					return
	
	# Check if the target area is clear
	if target_grid.all_cells_are_clear(occupied_cells, []):
		transfer_item_to_grid(item_held, target_grid, test_position)
	else:
		item_held.global_position = item_last_position
		offset = Vector2.ZERO
		item_held = null

# Transfer an item from current grid to another
func transfer_item_to_grid(item: InventoryItem, target_grid: Inventory, position: Vector2) -> void:
	remove_child(item)
	target_grid.add_child(item)
	
	item.global_position = position
	item.grid_map = target_grid
	
	item_held = null
	offset = Vector2.ZERO
	
	emit_signal("item_transferred", item, self, target_grid)

##Returns a list of all the items that are in the inventory (excluding the hover rect)
func get_items() -> Array:
	return get_children().slice(1, get_children().size())
