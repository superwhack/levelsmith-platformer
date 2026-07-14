extends Node

# Reference to the asset manager
@export var assetManager : AssetManager;

# All types of aduio
var audioTypes : Array[String] = ["BounceTile", "CoinPickup", "EnemyDeath", "EnemyShoot", "HazardTile", "PlayerDeath", "PlayerJump", "Victory", "WalkingGeneral", "WalkingIce", "WalkingSlime"];


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass;

## Replaces the currently previewed audio  with one chosen via file dialog.
## newAudioPath: The file path of the new audio replacing the old one.x 
func replace_audio(newAudioPath: String) -> void:
	pass;
	
## Clears the audio in a given folder and replaces it with a default
func reset_audio() -> void:
	pass;
	
