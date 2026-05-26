extends Node2D

# Is the player paused or running?
enum PlayState {
	PAUSE,
	PLAY
}

var playState := PlayState.PLAY; 
var goalReached := false;

# When pause is pressed, flip the current state
func pausePressed() -> void:
	if playState == PlayState.PAUSE:
		get_tree().paused = false;
		playState = PlayState.PLAY;
	else:
		get_tree().paused = true;
		playState = PlayState.PAUSE;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pausePressed();
	pass
