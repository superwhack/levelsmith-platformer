extends Node2D

# State variable to represent the state the game is currently in
var state : Global.State = Global.State.PLAY;

## Swap to edit state
func edit() -> void:
	print("Edit")
	# Update state variable
	state = Global.State.EDIT;
	# Change scene to edit scene
	get_tree().change_scene_to_file("res://Scenes/node_2d.tscn")

## Swap to play
func play() -> void:
	print("Play")
	# Update state variable
	state = Global.State.PLAY;
	# Change scene to play 
	get_tree().change_scene_to_file("res://Scenes/play_scene.tscn");
