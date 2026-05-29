extends HBoxContainer

@onready var editorManager : Node2D = get_parent().get_parent().get_parent();

var tileButtons: Array[Control] = [];
var objectButtons: Array[Control] = [];

# NOTE: These get_child calls will have to change once all buttons are in
func _ready() -> void:
	tileButtons.resize(6);
	tileButtons[0] = get_child(0);
	tileButtons[1] = get_child(1);
	tileButtons[2] = get_child(2);
	tileButtons[3] = get_child(3);
	tileButtons[4] = get_child(4);
	tileButtons[5] = get_child(5);
	
	objectButtons.resize(3);
	objectButtons[0] = get_child(6);
	objectButtons[1] = get_child(7);
	objectButtons[2] = get_child(8);

## Set objects to be transparent when the cursor is selected
## selected: True if the cursor is selected
func cursorSelected(selected: bool) -> void:
	if !selected:
		for tileButton in tileButtons:
			tileButton.modulate = Color(1, 1, 1, 1);
		for objectButton in objectButtons:
			objectButton.modulate = Color(1, 1, 1, 0.5);
	else:
		for tileButton in tileButtons:
			tileButton.modulate = Color(1, 1, 1, 0.5);
		for objectButton in objectButtons:
			objectButton.modulate = Color(1, 1, 1, 1);

# Tile Buttons
func _on_solid_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.SOLID);

func _on_death_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.DEATH);

func _on_oneway_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.ONEWAY);

func _on_ice_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.ICE);

func _on_sticky_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.STICKY);

func _on_bounce_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.BOUNCE);

# Object Buttons
func _on_slope_object_button_pressed() -> void:
	editorManager.update_brush_tile(Global.ObjectType.SLOPE);
	
func _on_spawn_object_button_pressed() -> void:
	editorManager.update_brush_tile(Global.ObjectType.SPAWN);

func _on_patrolling_object_button_pressed() -> void:
	editorManager.update_brush_tile(Global.ObjectType.PATROLLING);
