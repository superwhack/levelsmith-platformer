extends Area2D

## Runs when this node is first created.
## Hooks signals
func _ready() -> void:
	body_entered.connect(complete_level);

## If the player enters the area, emit the completion signal
## body: the body entering to check if it's the player
func complete_level(body: Node2D) -> void:
	if body is CharacterBody2D:
		AudioManager.play_effect("Victory");
		Global.complete.emit();
