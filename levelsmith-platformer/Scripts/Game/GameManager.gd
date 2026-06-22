extends Node2D

@export var pauseScreen: PanelContainer;
@export var bottomScreenGroup: Control;

# Button references for signals
@export var resetButton: Button;
@export var pauseButton: Button;
@export var resumeButton: Button;

# Is the player paused or running?
enum PlayState {
	PAUSE,
	PLAY
}

var playState := PlayState.PLAY; 
var goalReached := false;

var player: CharacterBody2D;
var playerStartingPosition: Vector2;

var tileSet: TileMapLayer;

var playerPreset: Resource;

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
	player = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1];
	player.playerMovementPreset = playerPreset;
	player.apply_preset(playerPreset);
	playerStartingPosition = player.position;
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_INHERIT);
	var enemyProperties = DirAccess.get_files_at("res://Resources/Enemies/");
	for enemyProperty in enemyProperties:
		var propertyFile = load("res://Resources/Enemies/" + enemyProperty);
		for node in tileSet.get_children():
			if tileSet.local_to_map(node.global_position) == propertyFile.position:
				(node as Enemy).apply_script(propertyFile);
				break;
	player.process_mode = Node.PROCESS_MODE_INHERIT;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

## Make all connections
func _ready() -> void:
	Global.death.connect(reset);
	resetButton.pressed.connect(reset);
	pauseButton.pressed.connect(pause);
	resumeButton.pressed.connect(pause);
