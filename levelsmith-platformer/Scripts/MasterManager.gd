extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.PLAY;

@export var editorManager : Node2D;
@export var gameManager : Node2D;

## Swap to edit state
func edit() -> void:
	print("Edit")
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	gameManager.hide();
	editorManager.show();

## Swap to play
func play() -> void:
	print("Play")
	# Update state variable
	state = Global.State.PLAY;
	# Change scene to play 
	gameManager.show();
	editorManager.hide();
