extends Area2D

@export var animatedSprite : AnimatedSprite2D;

## Runs when this node is first created.
## Hooks signals
func _ready() -> void:
	body_entered.connect(collect_checkpoint);

	animatedSprite.play();
	Global.checkpointCollected.connect(make_inactive);
	animatedSprite.animation_finished.connect(_on_animation_finished);
	animatedSprite.sprite_frames = AnimationManager.checkpointTemplateSprite.sprite_frames;

## Make the current checkpoint inactive, triggers across all checkpoints
func make_inactive(_position : Vector2 = Vector2(0,0)) -> void:
	animatedSprite.play("CheckpointInactive");

## Make the current animation active once it's been fully collected
func _on_animation_finished(_position : Vector2 = Vector2(0,0)) -> void:
	animatedSprite.play("CheckpointActive");

## If the player enters the area, emit the checkpoint collected signal
## body: the body entering to check if it's the player
func collect_checkpoint(body: Node2D) -> void:
	if body is Player && animatedSprite.animation == "CheckpointInactive":
		Global.checkpointCollected.emit(position);
		animatedSprite.play("CheckpointCollected");
		AudioManager.play_effect("Checkpoint");
