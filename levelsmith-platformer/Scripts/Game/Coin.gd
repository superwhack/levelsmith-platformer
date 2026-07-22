class_name Coin
extends Area2D

# Reference to the animated sprite
@export var animatedSprite : AnimatedSprite2D;

## When the node enters the scne tree, add it to the coin group, connect it's signal, and update its sprite frames
func _ready() -> void:
	add_to_group("Coin");
	body_entered.connect(_on_body_entered);
	animatedSprite.sprite_frames = AnimationManager.coinTemplateSprite.sprite_frames;

## Collect and delete the coin when the player enters it
## body : The body entering the coin
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Global.onCoinCollected.emit();
		AudioManager.play_effect("CoinPickup");
		queue_free();
