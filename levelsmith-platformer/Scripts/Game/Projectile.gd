extends Area2D

@export var onScreen : VisibleOnScreenEnabler2D;

#var direction : float;
var speed : float;
var bounceable : bool;

func _ready() -> void:
	body_entered.connect(delete_projectile);
	onScreen.screen_exited.connect(delete_projectile);

func _process(delta: float) -> void:
	global_position += transform.x * delta * speed * 100;

## Delete this projectile once it's offscreen
func delete_projectile(body: Node2D = null) -> void:
	if body == null:
		queue_free();
	elif body is TileMapLayer:
		queue_free();
