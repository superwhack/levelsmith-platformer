extends Node2D

# References for other screens
@export var pauseScreen : PanelContainer;
@export var bottomScreenGroup : Control;

# Button references for signals
@export var resetButton : Button;
@export var pauseButton : Button;
@export var resumeButton : Button;

# Is the player paused or running?
enum PlayState {
	PAUSE,
	PLAY
}
var playState : PlayState = PlayState.PLAY; 

# Has the goal been reached
var goalReached : bool = false;

# Player and its position
var player : CharacterBody2D;
var playerStartingPosition : Vector2;

# Reference to the tile set
var tileMap : TileMapLayer;

# Reference to the selected player preset
var playerPreset : Resource;

## When pause is pressed, flip the current state
func pause() -> void:

	if playState == PlayState.PAUSE:
		get_tree().paused = false;
		pauseScreen.hide();
		bottomScreenGroup.show();
		playState = PlayState.PLAY;
	else:
		get_tree().paused = true;
		pauseScreen.show();
		bottomScreenGroup.hide();
		playState = PlayState.PAUSE;

## Reset the play state through the global signal. Causes the level scene to be reloaded.
func reset() -> void:
	Global.reload.emit();
	start();

## The first function that runs when the game starts, this makes sure the logic regarding the newly spawned in player is wired correctly
func start() -> void:
	# Await 5 process frames so the Player that has just been added to GameManager can be selected in the tree
	for frame in range(1, 5):
		await get_tree().process_frame;

	# Get a reference to the player and apply its preset
	player = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1];
	player.playerMovementPreset = playerPreset;
	player.apply_preset(playerPreset);
	playerStartingPosition = player.position;
	if !player.healthChanged.is_connected(change_health):
		player.healthChanged.connect(change_health);

	# Unpause enemies and set their properties
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_INHERIT);
	var enemyProperties : PackedStringArray = DirAccess.get_files_at("res://Resources/Enemies/");
	for enemyProperty in enemyProperties:
		var propertyFile : Resource = load("res://Resources/Enemies/" + enemyProperty);
		for node in tileMap.get_children():
			if tileMap.local_to_map(node.global_position) == propertyFile.position:
				(node as Enemy).apply_script(propertyFile);
				break;

	# Unpause player
	player.process_mode = Node.PROCESS_MODE_INHERIT;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

## Record a change in health for the player
## newHealth: The new health of the player
func change_health(newHealth : int):
	print("Health: ", newHealth);

## Connects the death, reset, and pause signals to their respective functions.
func _ready() -> void:
	Global.death.connect(reset);
	resetButton.pressed.connect(reset);
	pauseButton.pressed.connect(pause);
	resumeButton.pressed.connect(pause);
