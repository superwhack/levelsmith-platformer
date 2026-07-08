extends Node2D

# References for other screens
@export var pauseScreen : PanelContainer;
@export var winScreen : PanelContainer;
@export var bottomScreenGroup : Control;
@export var coinCounterLabel : RichTextLabel;
@export var playerHealthUI : HBoxContainer;
@export var timerLabel : RichTextLabel;
@export var winCoinLabel : RichTextLabel;
@export var coinMargin : MarginContainer;
@export var winTimeLabel : RichTextLabel;

# Button references for signals
@export var resetButton : Button;
@export var pauseButton : Button;
@export var resumeButton : Button;
@export var replayButton : Button;
@export var editorButton : Button;

@export var cameraManager : Node;

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

# Coin variables
var coinCount : int = 0
var totalCoins : int = 0

# Player and its position
var player : CharacterBody2D;
var playerStartingPosition : Vector2;

# Reference to the tile set
var tileMap : TileMapLayer;

# Reference to the selected player preset
var playerPreset : Resource;

## When pause is pressed, flip the current state
func pause() -> void:
	if goalReached:
		return;
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
	AudioManager.play_UI_effect("UI_Selection");
	pauseButton.show();
	get_tree().paused = false;
	winScreen.hide();
	goalReached = false;
	Global.reload.emit();
	start();

## The first function that runs when the game starts, this makes sure the logic regarding the newly spawned in player is wired correctly
func start() -> void:
	pauseButton.show();
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
	
	# Await 5 process frames so the Player that has just been added to GameManager can be selected in the tree
	for frame in range(1, 5):
		await get_tree().process_frame;

	# Get a reference to the player and apply its preset
	player = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1];
	player.playerMovementPreset = playerPreset;
	player.apply_preset(playerPreset);
	playerStartingPosition = player.position;
	cameraManager.adjust_smoothing();
	cameraManager.process_player_camera(true);
	if playerHealthUI:
		playerHealthUI.bind_player(player);

	# Unpause enemies and set their properties
	get_tree().set_group("Enemy", "process_mode", Node.PROCESS_MODE_INHERIT);
	get_tree().set_group("Moving", "process_mode", Node.PROCESS_MODE_INHERIT);
	var enemyProperties : PackedStringArray = DirAccess.get_files_at("res://Resources/Enemies/");
	for enemyProperty in enemyProperties:
		var propertyFile : Resource = load("res://Resources/Enemies/" + enemyProperty);
		for node in tileMap.get_children():
			if tileMap.local_to_map(node.global_position) == propertyFile.position:
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

	# Start level timer
	testingTime = 0.0;
	timerRunning = true;
	timerLabel.show();
	update_timer(timerLabel);
	
	AnimationManager.play_all_animations();

## Connects the death, reset, and pause signals to their respective functions.
func _ready() -> void:
	Global.death.connect(reset);
	Global.complete.connect(print_level_completion_time);
	Global.complete.connect(level_complete);
	Global.onCoinCollected.connect(_on_coin_collected);
	resetButton.pressed.connect(reset);
	pauseButton.pressed.connect(pause);
	resumeButton.pressed.connect(pause);
	replayButton.pressed.connect(replay_level);
	editorButton.pressed.connect(return_to_editor);

func _process(delta: float) -> void:
	if timerRunning:
		testingTime += delta;
		update_timer(timerLabel);

## Increase coin count and update its UI on coin collection
func _on_coin_collected() -> void:
	coinCount += 1;
	print("Coin collected: ",coinCount);
	update_coin_counter(coinCounterLabel);

## Updates the coin counter shown on screen
func update_coin_counter(label: RichTextLabel) -> void:
	label.clear()
	if totalCoins > 0:
		label.append_text("Coins: %d / %d" % [coinCount, totalCoins])

## Prints the final completion time and stops the level timer
func print_level_completion_time() -> void:
	goalReached = true;
	timerRunning = false;
	var minutes := int(testingTime) / 60;
	var seconds := int(testingTime) % 60;
	print("Completion Time: %02d:%02d" % [minutes, seconds]);

## Updates the specified timer label with the current elapsed time
## label: The timer label to update
func update_timer(label: RichTextLabel) -> void:
	var minutes := int(testingTime) / 60;
	var seconds := int(testingTime) % 60;
	label.clear();
	label.append_text("Time: %02d:%02d" % [minutes, seconds]);

## Pauses gameplay, displays the win screen, and updates the completion statistics
func level_complete() -> void:
	goalReached = true;
	pauseButton.hide();
	get_tree().paused = true;
	update_coin_counter(winCoinLabel);
	update_timer(winTimeLabel);
	timerLabel.hide();
	winScreen.show();
	bottomScreenGroup.hide();

## Returns to the level editor and restores the editor state
func return_to_editor() -> void:
	get_tree().paused = false;
	winScreen.hide();
	goalReached = false;
	timerRunning = false;
	get_parent().edit();
	get_parent().editorManager.isValidated = true;

## Restarts the current level from the beginning
func replay_level() -> void:
	get_tree().paused = false;
	winScreen.hide();
	goalReached = false;
	reset();
