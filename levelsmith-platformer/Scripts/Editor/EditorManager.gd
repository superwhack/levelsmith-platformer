extends Node2D

# References to other managers
@export var toolManager: Node2D;
@export var masterManager: Node2D;

# References to grid TileMapLayer child nodes
@export var tileSet: TileMapLayer;
@export var previewTileSet: TileMapLayer;

# Relevant button elements
@export var playButton: Button;
@export var assetManagerButton: Button;

@export var assetManager: Control;

@export var customCursorManager: Node2D;

# Mouse position variables
var currentMousePosition: Vector2;
var prevMousePosition: Vector2;

# State of the hotbar
var currentHotbarState : Global.HotbarState;

# Flags
var isValidated: bool = false;
var isPlaceable: bool = true;
var playerExists: bool = false;
var goalExists: bool = false;

var returnClick: bool = false;

# Stores the number of tiles made
var tileCount : int = Global.TileType.size();

## Runs when the node first enters the tree
func _ready() -> void:
	assetManagerButton.pressed.connect(open_asset_manager);

## Runs every frame during the editing state
## _delta: how much time has passed
func _process(_delta: float) -> void:
	# record the position of the mouse on this frame
	currentMousePosition = get_grid_mouse_position(get_global_mouse_position());
	
	isPlaceable = !check_out_of_bounds(currentMousePosition);
	if (toolManager.currentTool == Global.Tool.BRUSH && tileSet.get_cell_source_id(currentMousePosition) >= tileCount): isPlaceable = false; 
	if (toolManager.currentTool == Global.Tool.CURSOR && tileSet.get_cell_source_id(currentMousePosition) < tileCount && tileSet.get_cell_source_id(currentMousePosition) >= 0): isPlaceable = false; 
	
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_DISABLED);

	playButton.modulate = Color(1, 1, 1) if playerExists && goalExists else Color(1, 1, 1, 0.5);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;


## NOTE: TEMPORARY FIX FUNCTION PT 1
## Clear all enemies without a property file
func clear_enemies(alwaysClear: bool = false) -> void:
	for child in tileSet.get_children():
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
	return tileSet.local_to_map(tileSet.to_local(mousePosition));
	
## Checks if the mouse is currently outside of the world grid size
## mousePosition: Where the mouse is during this check 
## returns: True if the mouse is out of bounds
func check_out_of_bounds(mousePosition: Vector2i) -> bool:
	return mousePosition.x < 0 || mousePosition.x >= get_parent().worldSize.x || mousePosition.y < 0 || mousePosition.y >= get_parent().worldSize.y;
	
## Reset all the enemy positions to the center of their tiles.
func reset_enemy_positions() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if (enemy is Enemy && enemy.propertyFile):
			enemy.global_position = tileSet.map_to_local(enemy.propertyFile.position);
			if enemy is EnemyPatrol || enemy is EnemyShooting:
				enemy.directionArrow.show();
				
## Opens the asset manager
func open_asset_manager() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = true;
	previewTileSet.hide();
	customCursorManager.invalidSprite.hide();
	assetManager.show();

func close_asset_manager() -> void:
	# WARNING: get_tree().paused has the potential to cause issues
	get_tree().paused = false;
	previewTileSet.show();
	assetManager.hide();
