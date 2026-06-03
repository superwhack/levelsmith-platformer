extends HBoxContainer

# Reference to editor manager
var editorManager : Node2D;

# References to button bars
@export var tiles : PanelContainer;
@export var entities : PanelContainer;

# References to tabs in Entity picker
@export var entityTab: HBoxContainer;
@export var propTab: HBoxContainer;

func _ready() -> void:
	pass;

## Toggles visibility of tile selection bar
## visibility: desired visibility
func display_tiles(visibility: bool):
	tiles.visible = visibility;

## Toggles visibility of entity selection bar
## visibility: desired visibility
func display_entities(visibility: bool):
	entities.visible = visibility;

## Toggles visibility of tabs
## index: index of tab selected
func entity_dropdown_select(index: int):
	match index:
		0:
			entityTab.visible = true;
			propTab.visible = false;
		1:
			entityTab.visible = false;
			propTab.visible = true;

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
	

# Prop Buttons
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
