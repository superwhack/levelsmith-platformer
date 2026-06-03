extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.EDIT;

# References to both state managers
@export var editorManager : Node2D;
@export var gameManager : Node2D;

# Map that is currently loaded in the Play scene
var loadedMap : TileMapLayer;

## NOTE: Magic numbers!!! This should be dynamic when loading/creating a level!
## Vars for the world size.
@export var worldSize : Vector2i = Vector2i(8, 14);

@export var propertyMenu : Panel;

func _ready() -> void:
	Global.reload.connect(load_tilemap);
	Global.complete.connect(level_complete);
	# Don't play this please, it's just for testing
	#AudioManager.play_music("Mindframe");
	
	edit();

## When the level is completed, validate it and automatically return to editor
## NOTE: In the future we may want to instead pop up a menu notifying the player of completion.
func level_complete() -> void:
	edit();
	editorManager.validationCheck = true;
	print("LEVEL COMPLETE")

## Swap to edit state
func edit() -> void:
	print("Edit")
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	gameManager.hide();
	gameManager.get_node("CanvasLayer").hide();
	editorManager.show();
	editorManager.get_node("CanvasLayer").show()
	# Play the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_INHERIT;

## Swap to play state
func play() -> void:
	if (!editorManager.player_exist()):
		print("No Player Exists, Cannot Start")
		return;
	propertyMenu.hide();
	print("Play")
	# Update state variable
	state = Global.State.PLAY;
	# Save map
	save_tilemap();
	# Change scene to play 
	gameManager.show();
	gameManager.start();
	gameManager.get_node("CanvasLayer").show()
	editorManager.hide();
	editorManager.previewTileMap.clear();
	editorManager.disable_box_brush();
	editorManager.get_node("CanvasLayer").hide();
	# Pause the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	# Reset the play scene and load the map
	gameManager.reset();
	gameManager.playerPreset = propertyMenu.selectedPreset;

## Saves the tilemap to the resource folder
func save_tilemap() -> void:
	# Reference the tile map as the node to be saved
	var nodeToSave = editorManager.get_node("Tiles");
	# Create a PackedScene
	var scene = PackedScene.new();
	# Pack the node to save as a scene
	scene.pack(nodeToSave)
	# Save that scene to the resource folder
	ResourceSaver.save(scene, "user://SavedTileMap.tscn");

## Loads the tilemap from the resource folder
func load_tilemap() -> void:
	# If any map is currently loaded, delete that
	if (loadedMap):
		gameManager.remove_child(loadedMap);
		loadedMap.queue_free();
	# Load the saved map from the resource folder
	var savedMap = load("user://SavedTileMap.tscn");
	# Instantiate the map as a scene instance
	var sceneInstance = savedMap.instantiate();
	# Add that instance to the top of the GameManager's hierarchy
	gameManager.add_child(sceneInstance);
	gameManager.move_child(sceneInstance, 0);
	loadedMap = gameManager.get_child(0);
