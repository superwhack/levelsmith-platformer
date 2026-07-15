extends Area2D

@export var animatedSprite : AnimatedSprite2D;
## Runs when this node is first created.
## Hooks signals
func _ready() -> void:
	body_entered.connect(collect_checkpoint);
	animatedSprite.sprite_frames = AnimationManager.checkpointTemplateSprite.sprite_frames;


## If the player enters the area, emit the completion signal
## body: the body entering to check if it's the player
func collect_checkpoint(body: Node2D) -> void:
	if body is Player:
		Global.checkpointCollected.emit(position);
