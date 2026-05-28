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
		Global.playerReset.emit(playerStartingPosition);
		# TODO: Implement resetting of all parts of the tile map, not just the player.

func start() -> void:
	## NOTE: Should figure out how to get this player to match the one the user plays as
	## right now it doesn't, it doesn't really break anything as far as I'm aware but it might.
	player = get_tree().get_first_node_in_group("Player")
	playerStartingPosition = player.position;
	Global.death.connect(reset);
	player.process_mode = Node.PROCESS_MODE_INHERIT;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_pressed();
