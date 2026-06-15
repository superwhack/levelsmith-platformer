extends HBoxContainer

# Reference to tool manager
@export var toolManager: Node2D;
@export var editorManager: Node2D;

# References to button bars
@export var tiles: PanelContainer;
@export var entities: PanelContainer;

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
			editorManager.change_current_hotbar(Global.HotbarState.ENTITIES);
			entityTab.visible = true;
			propTab.visible = false;
		1:
			editorManager.change_current_hotbar(Global.HotbarState.PROPS);
			entityTab.visible = false;
			propTab.visible = true;

# Tile Buttons
func _on_solid_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.SOLID);

func _on_death_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.DEATH);

func _on_oneway_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.ONEWAY);

func _on_ice_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.ICE);

func _on_sticky_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.STICKY);

func _on_bounce_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.BOUNCE);

func _on_slope_tile_button_pressed() -> void:
	toolManager.update_brush_object(Global.TileType.SLOPE);

# Object Buttons
func _on_goal_object_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.GOAL);

func _on_spawn_object_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PLAYER);

func _on_patrolling_object_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PATROLLING);

func _on_flying_object_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.FLYING);

# Prop Buttons
func _on_direction_marker_prop_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP1);

func _on_stop_marker_prop_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP2);

func _on_start_marker_prop_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP3);

func _on_end_marker_prop_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP4);

func _on_goal_marker_prop_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP5);
