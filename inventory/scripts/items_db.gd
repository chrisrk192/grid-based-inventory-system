extends Node

# Dictionary to store Item resources
var ITEMS: Dictionary = {}

func _ready():
	# Create all item resources
	_create_items()

func _create_items():
	# Create medkit
	var medkit = Item.new()
	medkit.item_id = 1
	medkit.name = "Medkit"
	medkit.stackable = true
	medkit.icon = load("res://assets/UI/Inventory/test/icon_cons_medkit.png")
	medkit.color = Color.DARK_RED
	medkit.value = 50
	medkit.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), 
						 Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), 
						 Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)])
	ITEMS[medkit.name] = medkit

	# Create AK47
	var ak47 = Item.new()
	ak47.item_id = 2
	ak47.name = "AK-47"
	ak47.stackable = false
	ak47.icon = load("res://assets/UI/Inventory/test/icon_wep_AK47.png")
	ak47.color = Color.DARK_GOLDENROD
	ak47.value = 1000
	ak47.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0),
					  Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1)])
	ITEMS[ak47.name] = ak47
	
	# Create revolver
	var revolver = Item.new()
	revolver.item_id = 3
	revolver.name = "Revolver"
	revolver.stackable = false
	revolver.icon = load("res://assets/UI/Inventory/test/icon_wep_python.png")
	revolver.color = Color.SADDLE_BROWN
	revolver.value = 700
	revolver.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0),
						  Vector2i(0,1), Vector2i(1,1), Vector2i(2,1),
						  Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)])
	ITEMS[revolver.name] = revolver
	
	# Create bullets
	var bullets = Item.new()
	bullets.item_id = 4
	bullets.name = "Bullets"
	bullets.stackable = true
	bullets.icon = load("res://assets/UI/Inventory/test/icon_ammo_boolets.png")
	bullets.color = Color.DARK_ORANGE
	bullets.value = 5
	bullets.grid_shape = _create_vector2i_array([Vector2i(0,0)])
	ITEMS[bullets.name] = bullets
	
	# Create Maxwell
	var maxwell = Item.new()
	maxwell.item_id = 5
	maxwell.name = "Maxwell"
	maxwell.stackable = false
	maxwell.icon = load("res://assets/UI/Inventory/maxwell.png")
	maxwell.color = Color.SADDLE_BROWN
	maxwell.value = 999
	maxwell.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0),
						 Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1),
						 Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2), Vector2i(4,2)])
	ITEMS[maxwell.name] = maxwell
	
	# Create Tetris L
	var tetris_l = Item.new()
	tetris_l.item_id = 6
	tetris_l.name = "Tetris L"
	tetris_l.stackable = false
	tetris_l.icon = load("res://assets/UI/Inventory/test/tetris_L.png")
	tetris_l.color = Color.BLUE
	tetris_l.value = 100
	tetris_l.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)])
	ITEMS[tetris_l.name] = tetris_l
	
	# Create Tetris T
	var tetris_t = Item.new()
	tetris_t.item_id = 7
	tetris_t.name = "Tetris T"
	tetris_t.stackable = false
	tetris_t.icon = load("res://assets/UI/Inventory/test/tetris_T.png")
	tetris_t.color = Color.GREEN
	tetris_t.value = 100
	tetris_t.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)])
	ITEMS[tetris_t.name] = tetris_t
	
	# Create Tetris Z
	var tetris_z = Item.new()
	tetris_z.item_id = 8
	tetris_z.name = "Tetris Z"
	tetris_z.stackable = false
	tetris_z.icon = load("res://assets/UI/Inventory/test/tetris_Z.png")
	tetris_z.color = Color.WHITE
	tetris_z.value = 100
	tetris_z.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)])
	ITEMS[tetris_z.name] = tetris_z
	
	# Create Tetris I
	var tetris_i = Item.new()
	tetris_i.item_id = 9
	tetris_i.name = "Tetris I"
	tetris_i.stackable = false
	tetris_i.icon = load("res://assets/UI/Inventory/test/tetris_I.png")
	tetris_i.color = Color.WHITE
	tetris_i.value = 100
	tetris_i.grid_shape = _create_vector2i_array([Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)])
	ITEMS[tetris_i.name] = tetris_i
	
	# Create Error item
	var error_item = Item.new()
	error_item.item_id = 0
	error_item.name = "Error"
	error_item.stackable = false
	error_item.icon = load("res://assets/UI/Inventory/gird_cell_error.png")
	error_item.color = Color.RED
	error_item.value = 0
	error_item.grid_shape = _create_vector2i_array([Vector2i(0,0)])
	ITEMS[error_item.name] = error_item
# Helper function to create a properly typed Array[Vector2i]
func _create_vector2i_array(vectors: Array) -> Array[Vector2i]:
	var typed_array: Array[Vector2i] = []
	for vector in vectors:
		typed_array.append(vector)
	return typed_array


func get_item(item_id: String) -> Item:
	return ITEMS[item_id] if item_id in ITEMS else ITEMS["error"]

func save_to_file(item_list: Array, file_path: String) -> void:
	if item_list.is_empty():
		print_rich("[color=red]Nothing to save![/color]")
		return
	
	var FILE: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	FILE.store_var(item_list)
	print_rich("[color=green]Item saved![/color]")
	FILE.close()

func load_from_file(file_path: String) -> Array:
	var FILE: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var data: Array = FILE.get_var()
	FILE.close()
	return data
