extends HBoxContainer

@onready var editorManager : Node2D = get_parent().get_parent().get_parent();

var tileButtons: Array[Control] = [];
var objectButtons: Array[Control] = [];
var propButtons: Array[Control] = [];

# NOTE: These get_child calls will have to change once all buttons are in
func _ready() -> void:
	tileButtons.resize(7);
	tileButtons[0] = get_child(0);
	tileButtons[1] = get_child(1);
	tileButtons[2] = get_child(2);
	tileButtons[3] = get_child(3);
	tileButtons[4] = get_child(4);
	tileButtons[5] = get_child(5);
	tileButtons[6] = get_child(6);
	
	objectButtons.resize(3);
	objectButtons[0] = get_child(7);
	objectButtons[1] = get_child(8);
	objectButtons[2] = get_child(9);
	
	propButtons.resize(5);
	propButtons[0] = get_child(10);
	propButtons[1] = get_child(11);
	propButtons[2] = get_child(12);
	propButtons[3] = get_child(13);
	propButtons[4] = get_child(14);


## Set objects to be transparent when the cursor is selected
## selected: True if the cursor is selected
func cursorSelected(selected: bool) -> void:
	if !selected:
		for tileButton in tileButtons:
			tileButton.modulate = Color(1, 1, 1, 1);
		for objectButton in objectButtons:
			objectButton.modulate = Color(1, 1, 1, 0.5);
		for propButton in propButtons:
			propButton.modulate = Color(1, 1, 1, 0.5);
	else:
		for tileButton in tileButtons:
			tileButton.modulate = Color(1, 1, 1, 0.5);
		for objectButton in objectButtons:
			objectButton.modulate = Color(1, 1, 1, 1);
		for propButton in propButtons:
			propButton.modulate = Color(1, 1, 1, 1);
			

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

func _on_slope_tile_button_pressed() -> void:
	editorManager.update_brush_tile(Global.TileType.SLOPE);

# Object Buttons
func _on_goal_object_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.GOAL);

func _on_spawn_object_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PLAYER);

func _on_patrolling_object_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PATROLLING);
	


func _on_direction_marker_prop_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PROP1);


func _on_stop_marker_prop_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PROP2);


func _on_start_marker_prop_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PROP3);


func _on_end_marker_prop_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PROP4);


func _on_goal_marker_prop_button_pressed() -> void:
	editorManager.update_brush_tile(Global.EntityType.PROP5);
