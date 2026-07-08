class_name Coin
extends Area2D

@export var animatedSprite : AnimatedSprite2D;

func _ready() -> void:
	add_to_group("Coin");
	body_entered.connect(_on_body_entered);
	animatedSprite.sprite_frames = AnimationManager.coinTemplateSprite.sprite_frames;

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Global.onCoinCollected.emit();
		queue_free();
