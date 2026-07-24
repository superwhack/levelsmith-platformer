extends Area2D

# The animated sprite of this scene
@export var animatedSprite : AnimatedSprite2D;

## Runs when this node is first created.
## Hooks signals
func _ready() -> void:
	body_entered.connect(collect_checkpoint);
	Global.checkpointCollected.connect(make_inactive);
	animatedSprite.animation_finished.connect(_on_animation_finished);
	# Set the sprite frames to the template sprite's frames
	animatedSprite.sprite_frames = AnimationManager.checkpointTemplateSprite.sprite_frames;

## Play the checkpoint's inactive animation
func make_inactive(_position : Vector2 = Vector2(0,0)) -> void:
	animatedSprite.play("CheckpointInactive");

## When the collected checkpoint animation finishes, play the active animation
func _on_animation_finished() -> void:
	if (animatedSprite.animation == "CheckpointCollected"):
		animatedSprite.play("CheckpointActive");

## If the player enters the area, emit the checkpoint collected signal and play the animation and sound
## body: the body entering to check if it's the player
func collect_checkpoint(body: Node2D) -> void:
	if body is Player && animatedSprite.animation == "CheckpointInactive":
		Global.checkpointCollected.emit(position);
		animatedSprite.play("CheckpointCollected");
		AudioManager.play_effect("CheckpointReached");
