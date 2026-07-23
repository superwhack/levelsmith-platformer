extends Node2D

# References for other screens
@export var pauseScreen : PanelContainer;
@export var winScreen : PanelContainer;
@export var bottomScreenGroup : Control;
@export var coinCounterLabel : RichTextLabel;
@export var playerHealthUI : HBoxContainer;
@export var timerLabel : RichTextLabel;
@export var winCoinLabel : RichTextLabel;
@export var winCoinHBox : HBoxContainer;
@export var coinMargin : MarginContainer;
@export var winTimeLabel : RichTextLabel;
@export var winScreenHealthUI : HBoxContainer;

# Button references for signals
@export var resetButton : Button;
@export var pauseButton : Button;
@export var resumeButton : Button;
@export var replayButton : Button;
@export var editorButton : Button;

# Manager references
@export var cameraManager : Node;
@export var masterManager : Node;

# Is the player paused or running?
enum PlayState {
	PAUSE,
	PLAY
}
var playState : PlayState = PlayState.PLAY; 

# Time tracker
var testingTime : float = 0.0;
var timerRunning : bool = false;

# Has the goal been reached
var goalReached : bool = false;
var pausable : bool = false;

# Coin variables
var coinCount : int = 0
var totalCoins : int = 0

# Player and its position
var player : CharacterBody2D;
var playerStartingPosition : Vector2;
var playerCheckpointPosition : Vector2 = Vector2(-1, -1);

# Reference to the tile set
var tileMap : TileMapLayer;

# Reference to the selected player preset
var playerPreset : Resource;

## When pause is pressed, flip the current state
func pause() -> void:
	if goalReached || !pausable:
		return;
	if playState == PlayState.PAUSE:
		get_tree().paused = false;
		pauseScreen.hide();
		bottomScreenGroup.show();
		playState = PlayState.PLAY;
		AudioManager.pause_music(false);
		AudioManager.pause_effects(false);
	else:
		get_tree().paused = true;
		pauseScreen.show();
		bottomScreenGroup.hide();
		playState = PlayState.PAUSE;
		AudioManager.pause_music(true);
		AudioManager.pause_effects(true);

## Reset the play state through the global signal. Causes the level scene to be reloaded.
func reset() -> void:
	freeze(true);
	await masterManager.screen_wipe_in();
	AudioManager.reset_audio();
	AudioManager.play_UI_effect("UISelection");
	AudioManager.play_music("LevelMusic");
	pauseButton.show();
	get_tree().paused = false;
	winScreen.hide();
	goalReached = false;
	Global.reload.emit();
	start();
	freeze(false);
	await masterManager.screen_wipe_out();

## Freeze/unfreeze this node and its children
## locked: true if this node is being disabled.
func freeze(locked: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if locked else Node.PROCESS_MODE_INHERIT;

## Resets the level from the beginning by removing the player's checkpoint.
func full_restart() -> void:
	playerCheckpointPosition = Vector2(-1, -1);
	pausable = false;
	await reset();

## The first function that runs when the game starts, this makes sure the logic regarding the newly spawned in player is wired correctly
func start() -> void:
	pauseButton.show();
	pausable = true;
	bottomScreenGroup.show();
	goalReached = false;
	# Reset coin values for the new level
	coinCount = 0;
	totalCoins = 0;
	# Count all coins that belong to the playable level and ignore coins that exist in the editor scene
	totalCoins = get_tree().get_node_count_in_group("Coin");
	if totalCoins > 0:
		coinCounterLabel.show();
		coinMargin.show();
		update_coin_counter(coinCounterLabel);
	else:
		coinCounterLabel.hide();
		coinMargin.hide();
		winCoinHBox.hide();
	
	# Waits until the player can be foundin the tree
	# The Editor state player means there will already be 1 in the group.
	while (get_tree().get_node_count_in_group("Player") == 1):
		await get_tree().process_frame;

	# Get a reference to the player and apply its preset
	player = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1];
	
	player.playerMovementPreset = playerPreset;
	player.apply_preset(playerPreset);
	playerStartingPosition = player.position;
	cameraManager.adjust_smoothing();
	cameraManager.snap_camera(player.global_position);
	if playerHealthUI:
		playerHealthUI.bind_player(player);

	# Unpause enemies and set their properties
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_INHERIT);
	get_tree().set_group("Moving", "process_mode", Node.PROCESS_MODE_INHERIT);
	var enemyProperties : PackedStringArray = DirAccess.get_files_at("user://Resources/Enemies/");
	for enemyProperty in enemyProperties:
		var propertyFile : Resource = load("user://Resources/Enemies/" + enemyProperty);
		for node in tileMap.get_children():
			if tileMap.local_to_map(node.global_position) == propertyFile.position:
				if !node is EnemyFlyer:
					node.position += Vector2(0, 20)
				node.apply_script(propertyFile);
				node.active = false;
				break;
	for moving in get_tree().get_nodes_in_group("Moving"):
		if moving is MovingPlatform && moving.propertyFile:
			moving.previewLine.hide();
			moving.previewPlatform.hide();
			moving.apply_progress();
		if moving is EnemyFlyer && moving.propertyFile:
			moving.previewLine.hide();

	# Unpause player
	player.process_mode = Node.PROCESS_MODE_INHERIT;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	
	# Set player position to the checkpoint
	if playerCheckpointPosition != Vector2(-1, -1):
		for node in tileMap.get_children():
			if (node.global_position - Vector2(1, 0)) == playerCheckpointPosition:
				node.animatedSprite.play("CheckpointActive");
		player.global_position = playerCheckpointPosition;
	else:
		testingTime = 0.0;

	# Start level timer
	timerRunning = true;
	timerLabel.show();
	update_timer(timerLabel);
	
	AnimationManager.play_all_animations();

## Connects the death, reset, and pause signals to their respective functions.
func _ready() -> void:
	Global.death.connect(reset);
	Global.goalReached.connect(goal_reached);
	Global.complete.connect(level_complete);
	Global.checkpointCollected.connect(collect_checkpoint);
	Global.onCoinCollected.connect(_on_coin_collected);
	resetButton.pressed.connect(full_restart);
	pauseButton.pressed.connect(pause);
	resumeButton.pressed.connect(pause);
	replayButton.pressed.connect(replay_level);
	editorButton.pressed.connect(return_to_editor);

## Runs every frame and updates the timer
func _process(delta: float) -> void:
	if timerRunning:
		testingTime += delta;
		update_timer(timerLabel);
		
func _unhandled_input(event: InputEvent) -> void:
	# Sets us into edit mode
	if (event.is_action_pressed("enter")):
		if(masterManager.state == Global.State.PLAY):
			masterManager.edit();
			return;

## Increase coin count and update its UI on coin collection
func _on_coin_collected() -> void:
	coinCount += 1;
	print("Coin collected: ",coinCount);
	update_coin_counter(coinCounterLabel);

## Updates the coin counter shown on screen
func update_coin_counter(label: RichTextLabel) -> void:
	label.clear()
	if totalCoins > 0:
		label.append_text("%02d" % [coinCount])

## Updates the player's checkpoint when they cross a new one.
func collect_checkpoint(newSpawn: Vector2) -> void:
	playerCheckpointPosition = newSpawn;
	
## Prints the final completion time and stops the level timer
func print_level_completion_time() -> void:
	timerRunning = false;
	var minutes : float = int(testingTime) / 60.0;
	var seconds : float = int(testingTime) % 60;
	print("Completion Time: %02d:%02d" % [minutes, seconds]);

## Updates the specified timer label with the current elapsed time
## label: The timer label to update
func update_timer(label : RichTextLabel) -> void:
	var minutes : float = int(testingTime) / 60.0;
	var seconds : float = int(testingTime) % 60;
	label.clear();
	label.append_text("%02d:%02d" % [minutes, seconds]);

## Pauses gameplay, displays the win screen, and updates the completion statistics
func level_complete() -> void:
	## If the goal's already been reached, don't run this again
	#if goalReached:
		#return;
	# AudioManager.reset_audio();
	AudioManager.stop_music_preview();
	print_level_completion_time();
	pauseButton.hide();
	pausable = false;
	get_tree().paused = true;
	update_coin_counter(winCoinLabel);
	update_timer(winTimeLabel);
	timerLabel.hide();
	winScreen.show();
	bottomScreenGroup.hide();
	winScreenHealthUI.bind_player(player);
	winScreenHealthUI.sync_to_player();
	masterManager.editorManager.isValidated = true;
	ImportExportManager.set_metadata(masterManager.loadedLevelPath, "validated", true);

## Returns to the level editor and restores the editor state
func return_to_editor() -> void:
	get_tree().paused = false;
	freeze(true);
	winScreen.hide();
	timerRunning = false;
	masterManager.edit();
	pausable = false;

## Restarts the current level from the beginning
func replay_level() -> void:
	get_tree().paused = false;
	winScreen.hide();
	full_restart();

## When global goal signal is emitted, disable the timer and hide the UI
func goal_reached() -> void:
	bottomScreenGroup.hide();
	timerRunning = false;
	goalReached = true;
