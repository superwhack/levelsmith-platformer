extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.EDIT;

# References to both state managers
var editorManager : Node2D;
var gameManager : Node2D;

# Map that is currently loaded in the Play scene
var loadedMap : TileMapLayer;
var gridWidth : int = 8;
var gridHeight : int = 14;

func _ready() -> void:
	editorManager = get_child(1);
	gameManager = get_child(2);
	Global.reload.connect(load_tilemap);
	
	edit();

## Swap to edit state
func edit() -> void:
	print("Edit")
	get_tree().set_group("Player", "process_mode", Node.PROCESS_MODE_DISABLED);
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	gameManager.hide();
	gameManager.get_node("CanvasLayer").hide();
	gameManager.reset();
	editorManager.show();
	editorManager.get_node("CanvasLayer").show()
	# Play the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_INHERIT;

## Swap to play state
func play() -> void:
	if (!editorManager.player_exist()):
		print("No Player Exists, Cannot Start")
		return;
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
	editorManager.get_node("CanvasLayer").hide();
	# Pause the editor manager
	editorManager.process_mode = Node.PROCESS_MODE_DISABLED;
	# Reset the play scene and load the map
	gameManager.reset();

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
