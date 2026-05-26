extends Node2D

# Is the player paused or running?
enum PlayState {
	PAUSE,
	PLAY
}

var playState := PlayState.PLAY; 
var goalReached := false;

# Player starting values
@export var player: CharacterBody2D;
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
	player.position = playerStartingPosition
	# TODO: Implement resetting of all parts of the tile map, not just the player.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerStartingPosition = player.position;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_pressed();
	pass
