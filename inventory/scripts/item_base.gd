class_name Item extends TextureRect

@export var actionList: MenuButton 
@export var grid_space: ColorRect 
@export var countLabel: Label
@export var shadow: ColorRect 

var grid_map: Inventory  # Changed from @onready to variable to allow changing the reference

var cur_size: Vector2 = Vector2.ZERO
var is_rotated: bool = false
var stackable: bool = false
var item_id: String = ""
var quantity: int = 1

const VALID_SPOT: Color = Color(0.45, 1, 0, 0.3) # The color for valid placement of items
const OCCUPIED_SPOT: Color = Color(1, 0, 0, 0.3) # the color of occupied areas
const SWITCH_SPOT: Color = Color(1, 0.68, 0, 0.3) # thr color when the area is occupied by other items
#----------------------------------------------------------#
func _ready() -> void:
	grid_map = get_parent() as Inventory  # Set initial grid reference
	countLabel.visible = false
	# making sure the signal isn't connected to stop godot from bitching
	if not ItemManager.is_connected("item_used", Callable(ItemManager, "_on_item_used")):
		ItemManager.connect("item_used", Callable(ItemManager, "_on_item_used"))

func _process(_delta: float) -> void:
	if grid_map != null:
		var zone: Rect2 = Rect2(grid_map.hover_rect.global_position, size)
		if grid_map.is_inside_rect(zone):
			shadow.global_position = grid_map.hover_rect.global_position
	
	if stackable:
		countLabel.text = "X" + str(quantity)
	shadow.visible = grid_map != null and grid_map.item_held == self

func prep_item(itemId: String = "") -> void:
	var item_property: Dictionary = ItemsDB.get_item(itemId) # get the item id from teh autoload and use it's data to configure teh item
	cur_size = item_property.grid_size * grid_map.cell_size
	
	item_id = itemId
	
	texture = load(item_property.icon) #NOTE: you may get an error here if you don't give the item an image in the items_db.gd autoload
	size = cur_size
	
	shadow.size = cur_size
	grid_space.size = cur_size
	actionList.size = cur_size
	
	stackable = item_property.stackble
	
	var actionPopUp: PopupMenu = actionList.get_popup()
	actionPopUp.add_item("Use", 0)
	
	# if the item can be stacked, then show the amount label (Item_count) and put the number there
	if stackable:
		actionPopUp.add_item("Split", 1)
		countLabel.visible = true
		countLabel.text = "X" + str(quantity)
	
	actionPopUp.add_item("Drop", 2)
	actionPopUp.id_pressed.connect(_on_menu_pressed)

# rotates the object by fliping the extents (width and height)
func rotate() -> void:
	# flips the size of the item so it "rotates"
	cur_size = Vector2(cur_size.y, cur_size.x)
	
	# change the sizes of all the items
	size = cur_size
	shadow.size = cur_size
	grid_space.size = cur_size
	
	grid_map.offset = -(cur_size / 2) # prevent long items from going far from the mouse by making it in the center
	
	# rotation the actual image because there have been a lot of problems with rotationg the textureRect node
	var image_res: Image = texture.get_image()
	image_res.rotate_90(CLOCKWISE)
	texture = ImageTexture.create_from_image(image_res)
	
	size = cur_size
	is_rotated = not is_rotated # change the rotation state so we can save it
	grid_map.emit_signal("item_rotated") # emits the signal after all of this is done

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
	# This item will call the Item manager's item used signal then from there custom functionalties is added
	ItemManager.emit_signal("item_used", item_id, quantity)

func split() -> void:
	if quantity / 2 >= 1:
		var item_instance: Item = grid_map.itemBase.instantiate()
		grid_map.add_child(item_instance)
		item_instance.prep_item(item_id)
		grid_map.item_held = item_instance
		
		# configuring the quantity of the item currently held and then the one that was splited from
		item_instance.quantity = quantity / 2 + (quantity % 2)
		quantity /= 2

# change this function to whatever you need it to be e.g drop an item to the world then delete it
func remove() -> void:
	ItemManager.disconnect("item_used", Callable(ItemManager, "_on_item_used"))
	queue_free()
