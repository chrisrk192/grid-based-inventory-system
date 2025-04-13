class_name InventoryItem extends TextureRect

@export var actionList: MenuButton 
@export var countLabel: Label

# Containers for cells
var cells_container: Node2D
var shadow_container: Node2D

var grid_map: Inventory  # Reference to the parent inventory
var item_stats: Item 
var grid_shape: Array = []  # Array of Vector2i for Tetris-like shapes
var is_rotated: bool = false
#var stackable: bool = false
#var item_id: String = ""
var quantity: int = 1
var cell_rects: Array = []  # Stores individual cell rects
var shadow_rects: Array = []  # Stores individual shadow rects

#const VALID_SPOT: Color = Color(0, 1, 0, 1) # Valid placement color
#const OCCUPIED_SPOT: Color = Color(1, 0, 0, 1) # Occupied areas color
#const SWITCH_SPOT: Color = Color(1, 1, 1, 0.75) # Swap possible color
#const CELL_BORDER_COLOR: Color = Color(0, 0, 0, 0.75) # Border color for cells

#----------------------------------------------------------#
func _ready() -> void:
	grid_map = get_parent() as Inventory
	countLabel.visible = false
	
	# Create containers for cells and shadows
	cells_container = Node2D.new()
	cells_container.name = "CellsContainer"
	cells_container.show_behind_parent = true
	add_child(cells_container)
	
	shadow_container = Node2D.new()
	shadow_container.name = "ShadowContainer"
	shadow_container.z_index = -1
	shadow_container.top_level = true
	add_child(shadow_container)
	
	# Connect item_used signal to ItemManager
	if not ItemManager.is_connected("item_used", Callable(ItemManager, "_on_item_used")):
		ItemManager.connect("item_used", Callable(ItemManager, "_on_item_used"))

func _process(_delta: float) -> void:
	if grid_map != null and grid_map.item_held == self:
		# Update shadow container position
		shadow_container.global_position = self.global_position.snappedf(grid_map.cell_size)
	
	if item_stats.stackable:
		countLabel.text = "X" + str(quantity)
	
	shadow_container.visible = grid_map != null and grid_map.item_held == self

func prep_item(itemId: String = "") -> void:
	item_stats = ItemsDB.get_item(itemId)
	grid_shape = item_stats.grid_shape.duplicate()
	
	
	# Calculate the bounding box size for the item based on its shape
	var bounds = get_shape_bounds()
	var shape_width = bounds.size.x
	var shape_height = bounds.size.y
	
	# Set the texture and size for the main item
	texture = item_stats.icon
	size = Vector2(shape_width * grid_map.cell_size, shape_height * grid_map.cell_size)
	
	# Set up the ActionList size
	actionList.size = size
	
	# Create individual cells for the grid shape
	create_cell_visuals()
		
	if item_stats.stackable:
		countLabel.visible = true
		countLabel.text = "X" + str(quantity)
		
	# Set up action menu
	var actionPopUp: PopupMenu = actionList.get_popup()
	actionPopUp.add_item("Use", 0)

	if item_stats.stackable:
		actionPopUp.add_item("Split", 1)
	
	actionPopUp.add_item("Drop", 2)
	actionPopUp.id_pressed.connect(_on_menu_pressed)


func show_menu() -> void:
	actionList.show_popup()
# Create visual cells for the item's grid shape
func create_cell_visuals() -> void:
	# Clear any existing cells
	for child in cells_container.get_children():
		print("Deleting ", child)
		child.queue_free()
	
	for child in shadow_container.get_children():
		print("Deleting ", child)
		child.queue_free()
	
	cell_rects.clear()
	shadow_rects.clear()
	
	# Create cells for each position in the grid shape
	for cell_pos in grid_shape:
		# Create grid cell
		var cell_rect = ColorRect.new()
		cell_rect.size = Vector2(grid_map.cell_size, grid_map.cell_size)
		cell_rect.position = Vector2(cell_pos.x * grid_map.cell_size, cell_pos.y * grid_map.cell_size)
		cell_rect.color = item_stats.color
		cells_container.add_child(cell_rect)
		cell_rects.append(cell_rect)
				
		# Create shadow cell (for placement preview)
		var shadow_rect = ColorRect.new()
		shadow_rect.size = Vector2(grid_map.cell_size, grid_map.cell_size)
		shadow_rect.position = Vector2(cell_pos.x * grid_map.cell_size, cell_pos.y * grid_map.cell_size)
		shadow_rect.color = item_stats.color
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_container.add_child(shadow_rect)
		shadow_rects.append(shadow_rect)
		

# Get the bounding box of the item's shape
func get_shape_bounds() -> Rect2:
	if grid_shape.size() == 0:
		return Rect2(0, 0, 1, 1)
	
	var min_x = 999
	var min_y = 999
	var max_x = -999
	var max_y = -999
	
	for cell in grid_shape:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

# Rotate the item clockwise
func rotate() -> void:
	var rotated_shape = []
	
	# Rotate each cell in the shape 90 degrees clockwise
	for cell in grid_shape:
		# (x,y) -> (y,-x) for 90-degree clockwise rotation
		rotated_shape.append(Vector2i(cell.y, -cell.x))
	
	grid_shape = rotated_shape
	
	# Normalize the shape to start at (0,0)
	normalize_shape()
	
	# Update the visual representation
	recalculate_size()
	
	
	# Rotate the texture
	if(texture != null):
		var image_res: Image = texture.get_image()
		image_res.rotate_90(CLOCKWISE)
		texture = ImageTexture.create_from_image(image_res)
	
	is_rotated = not is_rotated
	grid_map.emit_signal("item_rotated")

func recalculate_size() -> void:
	var bounds = get_shape_bounds()
	var shape_width = bounds.size.x
	var shape_height = bounds.size.y
	
	size = Vector2(shape_width * grid_map.cell_size, shape_height * grid_map.cell_size)
	actionList.size = size
	
	# Update cell visuals
	create_cell_visuals()

# Normalize the shape to start at (0,0)
func normalize_shape() -> void:
	var bounds = get_shape_bounds()
	var offset_x = bounds.position.x
	var offset_y = bounds.position.y
	
	if offset_x != 0 or offset_y != 0:
		for i in range(grid_shape.size()):
			grid_shape[i] = Vector2i(grid_shape[i].x - offset_x, grid_shape[i].y - offset_y)

# Get the global positions of all cells in the shape
func get_occupied_cells(base_position: Vector2 = global_position) -> Array:
	var cells = []
	
	for cell in grid_shape:
		var cell_pos = base_position + Vector2(cell.x * grid_map.cell_size, cell.y * grid_map.cell_size)
		cells.append(cell_pos)
	
	return cells

# Get the grid positions (in grid coordinates, not pixels) of all cells in the shape
func get_grid_coordinates(base_grid_pos: Vector2i) -> Array:
	var coords = []
	
	for cell in grid_shape:
		var grid_pos = Vector2i(base_grid_pos.x + cell.x, base_grid_pos.y + cell.y)
		coords.append(grid_pos)
	
	return coords

# Check if this item intersects with another at a given position
func would_intersect_with(other_item: InventoryItem, test_position: Vector2) -> bool:
	var this_cells = get_occupied_cells(test_position)
	var other_cells = other_item.get_occupied_cells()
	
	for this_cell in this_cells:
		for other_cell in other_cells:
			# Check if cells are in the same grid position
			var this_grid_pos = grid_map.world_to_grid(this_cell)
			var other_grid_pos = grid_map.world_to_grid(other_cell)
			
			if this_grid_pos == other_grid_pos:
				return true
	
	return false

#-------------------------------------------------#
func _on_menu_pressed(id: int) -> void:
	match id:
		0:
			use()
		1:
			split()
		2:
			remove()

func use() -> void:
	ItemManager.emit_signal("item_used", item_stats.item_id, quantity)

func split() -> void:
	if quantity / 2 >= 1:
		var item_instance: InventoryItem = grid_map.itemBase.instantiate()
		grid_map.add_child(item_instance)
		item_instance.prep_item(item_stats.name)
		grid_map.item_held = item_instance
		
		# Split quantity between original and new item
		item_instance.quantity = quantity / 2 + (quantity % 2)
		quantity /= 2

func remove() -> void:
	if ItemManager.is_connected("item_used", Callable(ItemManager, "_on_item_used")):
		ItemManager.disconnect("item_used", Callable(ItemManager, "_on_item_used"))
	
	print("Deleting ", self)
	queue_free()
