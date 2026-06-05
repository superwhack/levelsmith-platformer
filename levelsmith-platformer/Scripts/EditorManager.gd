extends Node2D

# References to other managers
@export var toolManager: Node2D;
@export var masterManager: Node2D;

# References to grid TileMapLayer child nodes
@export var tileSet: TileMapLayer;

# Play button
@export var playButton: Button;

# Mouse position variables
var currentMousePosition: Vector2;
var prevMousePosition: Vector2;

# State of the hotbar
var currentHotbarState : Global.HotbarState;

# Flags
var isValidated: bool = false;
var isPlaceable: bool = true;
var playerExists: bool = false;

# Stores the number of tiles made
var tileCount := Global.TileType.size();

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
	
	playButton.modulate = Color(1, 1, 1) if playerExists else Color(1, 1, 1, 0.5);
	
	# save the mouse position to the previous frame
	prevMousePosition = currentMousePosition;

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
	if (mousePosition.x < 0
	|| mousePosition.x > get_parent().worldSize.x
	|| mousePosition.y < 0
	|| mousePosition.y > get_parent().worldSize.y):
		return true;
	return false;
