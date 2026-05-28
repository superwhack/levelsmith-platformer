extends Node2D

# Is the player paused or running?
enum PlayState {
	PAUSE,
	PLAY
}

var playState := PlayState.PLAY; 
var goalReached := false;

var player: CharacterBody2D;
var playerStartingPosition: Vector2;

# When pause is pressed, flip the current state
func pause_pressed() -> void:
	if playState == PlayState.PAUSE:
		get_tree().paused = false;
		playState = PlayState.PLAY;
	else:
		get_tree().paused = true;
		playState = PlayState.PAUSE;

## Reset the play state, player position as well as all tile positions and information
func reset() -> void:
	if player:
		# Send a signal to reset player position
		#Global.playerReset.emit(playerStartingPosition);
		player.position = playerStartingPosition;
		player.velocity = Vector2(0, 0);
		# TODO: Implement resetting of all parts of the tile map, not just the player.

## The first function that runs when the game starts, this makes sure the logic regarding the newly spawned in player is wired correctly
func start() -> void:
	# Await 5 process frames so the Player that has just been added to GameManager can be selected in the tree
	for frame in range(1, 5):
		await get_tree().process_frame
	player = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1]
	playerStartingPosition = player.position;
	Global.death.connect(reset);
	player.process_mode = Node.PROCESS_MODE_INHERIT;

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_pressed();
