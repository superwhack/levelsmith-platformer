extends Area2D

@export var animatedSprite : AnimatedSprite2D;

#var initailyActive = false;
## Runs when this node is first created.
## Hooks signals
func _ready() -> void:
	body_entered.connect(collect_checkpoint);

	animatedSprite.play();
	Global.checkpointCollected.connect(make_inactive);
	animatedSprite.animation_finished.connect(_on_animation_finished);
	animatedSprite.sprite_frames = AnimationManager.checkpointTemplateSprite.sprite_frames;

func make_inactive(_position : Vector2 = Vector2(0,0)) -> void:
	animatedSprite.play("CheckpointInactive");

func _on_animation_finished(_position : Vector2 = Vector2(0,0)) -> void:
	animatedSprite.play("CheckpointActive");

## If the player enters the area, emit the completion signal
## body: the body entering to check if it's the player
func collect_checkpoint(body: Node2D) -> void:
	if body is Player && animatedSprite.animation == "CheckpointInactive":
		Global.checkpointCollected.emit(position);
		animatedSprite.play("CheckpointCollected");
