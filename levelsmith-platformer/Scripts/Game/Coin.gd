class_name Coin
extends Area2D

func _ready() -> void:
	add_to_group("Coin");
	body_entered.connect(_on_body_entered);

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Global.onCoinCollected.emit();
		AudioManager.play_effect("CoinPickup");
		queue_free();
