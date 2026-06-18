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

@export var tileMap: TileMapLayer;

# References to all Tile buttons
@export var solidTileButton: Button;
@export var oneWayTileButton: Button;
@export var deathTileButton: Button;
@export var iceTileButton: Button;
@export var stickyTileButton: Button;
@export var bounceTileButton: Button;
@export var slopeTileButton: Button;

# References to all Entity buttons;
@export var goalEntityButton: Button;
@export var playerEntityButton: Button;
@export var patrollingEntityButton: Button;
@export var shootingEntityButton: Button;
@export var flyingEntityButton: Button;

# References to all Prop buttons
@export var propOneButton: Button;
@export var propTwoButton: Button;
@export var propThreeButton: Button;
@export var propFourButton: Button;
@export var propFiveButton: Button;

# Misc object references
@export var entityPropDropdown : OptionButton;

func _ready() -> void:
	# Connect all Tile button signals
	solidTileButton.pressed.connect(_on_solid_tile_button_pressed);
	oneWayTileButton.pressed.connect(_on_oneway_tile_button_pressed);
	deathTileButton.pressed.connect(_on_death_tile_button_pressed);
	iceTileButton.pressed.connect(_on_ice_tile_button_pressed);
	stickyTileButton.pressed.connect(_on_sticky_tile_button_pressed);
	bounceTileButton.pressed.connect(_on_bounce_tile_button_pressed);
	slopeTileButton.pressed.connect(_on_slope_tile_button_pressed);
	
	# Connect all Entity button signals
	goalEntityButton.pressed.connect(_on_goal_entity_button_pressed);
	playerEntityButton.pressed.connect(_on_player_entity_button_pressed);
	patrollingEntityButton.pressed.connect(_on_patrolling_entity_button_pressed);
	shootingEntityButton.pressed.connect(_on_shooting_entity_button_pressed);
	flyingEntityButton.pressed.connect(_on_flying_entity_button_pressed);
	
	# Connect all Prop button signals
	propOneButton.pressed.connect(_on_prop_one_button_pressed);
	propTwoButton.pressed.connect(_on_prop_two_button_pressed);
	propThreeButton.pressed.connect(_on_prop_three_button_pressed);
	propFourButton.pressed.connect(_on_prop_four_button_pressed);
	propFiveButton.pressed.connect(_on_prop_five_button_pressed);
	
	entityPropDropdown.item_selected.connect(entity_dropdown_select);

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
			toolManager.update_brush_object(Global.EntityType.PLAYER);
			toolManager.currentObjectRotation = 0;
			entityTab.visible = true;
			propTab.visible = false;
		1:
			editorManager.change_current_hotbar(Global.HotbarState.PROPS);
			toolManager.update_brush_object(Global.EntityType.PROP1);
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
func _on_goal_entity_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.GOAL);

func _on_player_entity_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PLAYER);

func _on_patrolling_entity_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PATROLLING);

func _on_shooting_entity_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.SHOOTING);

func _on_flying_entity_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.FLYING);

# Prop Buttons
func _on_prop_one_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP1);

func _on_prop_two_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP2);

func _on_prop_three_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP3);

func _on_prop_four_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP4);

func _on_prop_five_button_pressed() -> void:
	toolManager.update_brush_object(Global.EntityType.PROP5);
