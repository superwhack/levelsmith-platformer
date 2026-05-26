extends Node2D

var state : Global.State = Global.State.PLAY;

# Swap to edit
func Edit() -> void:
	print("Edit")
	state = Global.State.EDIT;

# Swap to play
func Play() -> void:
	print("Play")
	state = Global.State.PLAY;
