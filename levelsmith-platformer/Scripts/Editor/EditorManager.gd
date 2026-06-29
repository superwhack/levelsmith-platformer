extends Node2D

# References to other managers
@export var toolManager : Node2D;
@export var masterManager : Node2D;

# References to grid TileMapLayer child nodes
@export var tileMap : TileMapLayer;
@export var previewTileMap : TileMapLayer;

# Relevant button elements
@export var playButton : Button;
@export var assetManagerButton : Button;
@export var exportButton : Button;

# Asset Manager
@export var assetManager : Control;

# Cursor Manager
@export var customCursorManager : Node2D;

# Mouse position variables
var currentMousePosition : Vector2;
var prevMousePosition : Vector2;

# State of the hotbar
var currentHotbarState : Global.HotbarState;

# Flags
var isValidated : bool = false;
var isPlaceable : bool = true;
var playerExists : bool = false;
var goalExists : bool = false;

var returnClick : bool = false;

# Stores the number of tiles made
var tileCount : int = Global.TileType.size();

## Runs when the node first enters the tree
func _ready() -> void:
	var reset_player_and_goal = func() -> void:
		playerExists = false;
		goalExists = false;
	
	var export_level = func() -> void:
		masterManager.propertyMenu.close();
		ImportExportManager.export_level(tileMap, masterManager.propertyMenu, masterManager.worldSize);
	
	assetManagerButton.pressed.connect(open_asset_manager);
	Global.levelCreated.connect(reset_player_and_goal);
	exportButton.pressed.connect(export_level);

## Runs every frame during the editing state
## _delta: how much time has passed since the last frame
func _process(_delta: float) -> void:
	# Record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());
	# Check if the tile is placeable in this spot
	isPlaceable = !check_out_of_bounds(currentMousePosition);
	
	if (toolManager.currentTool == Global.Tool.BRUSH && tileMap.get_cell_source_id(currentMousePosition) >= tileCount): isPlaceable = false; 
	
	if (toolManager.currentTool == Global.Tool.CURSOR && tileMap.get_cell_source_id(currentMousePosition) < tileCount && tileMap.get_cell_source_id(currentMousePosition) >= 0): isPlaceable = false;
	 
	# Pause the player and enemies
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	get_tree().set_group("Moving", "process_mode", Node.PROCESS_MODE_DISABLED);

	playButton.modulate = Color(1, 1, 1) if playerExists && goalExists else Color(1, 1, 1, 0.5);
	
	# Save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;


## NOTE: TEMPORARY FIX FUNCTION PT 1
## Clear all enemies without a property file
func clear_enemies(alwaysClear: bool = false) -> void:
	for child in tileMap.get_children():
		if child is Enemy:
			if alwaysClear || child.propertyFile == null:
				child.queue_free();

## Changes current hotbar state (used for hotkeys)
## newState: Global.HotbarState
func change_current_hotbar(newState: Global.HotbarState):
	currentHotbarState = newState;

## Converts the mouse's position into grid coordinates.
## mousePosition: Where the cursor currently is in world space.
## returns: The grid-coordinate equivalent of the position.
func get_grid_mouse_position(mousePosition: Vector2) -> Vector2:
	return tileMap.local_to_map(tileMap.to_local(mousePosition));
	
## Checks if the mouse is currently outside of the world grid size
## mousePosition: Where the mouse is during this check 
## returns: True if the mouse is out of bounds
func check_out_of_bounds(mousePosition: Vector2i) -> bool:
	return mousePosition.x < 0 || mousePosition.x >= masterManager.worldSize.x || mousePosition.y < 0 || mousePosition.y >= masterManager.worldSize.y;
	
## Reset all the enemy positions to the center of their tiles.
func reset_enemy_positions() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if (enemy is Enemy && enemy.propertyFile):
			enemy.global_position = tileMap.map_to_local(enemy.propertyFile.position);
			if enemy is EnemyPatrol || enemy is EnemyShooting:
				enemy.directionArrow.show();
	for moving in get_tree().get_nodes_in_group("Moving"):
		if moving is MovingPlatform && moving.propertyFile:
			moving.global_position = tileMap.map_to_local(moving.propertyFile.position);
			moving.previewPlatform.show();

## Opens the asset manager
func open_asset_manager() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = true;
	previewTileMap.hide();
	customCursorManager.invalidSprite.hide();
	assetManager.show();

## Closes the asset manager
func close_asset_manager() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = false;
	previewTileMap.show();
	assetManager.hide();
