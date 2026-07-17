extends Area2D

@export var animatedSprite : AnimatedSprite2D;
## Runs when this node is first created.
## Hooks signals
func _ready() -> void:
	body_entered.connect(complete_level);
	animatedSprite.sprite_frames = AnimationManager.goalTemplateSprite.sprite_frames;


## If the player enters the area, emit the completion signal
## body: the body entering to check if it's the player
func complete_level(body: Node2D) -> void:
	if body is Player:
		body.play_victory();
		AudioManager.pause_music(true);
