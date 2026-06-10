extends Area2D

@export var onScreen : VisibleOnScreenEnabler2D;

#var direction : float;
var speed : float;

func _ready() -> void:
	body_entered.connect(delete_projectile);
	onScreen.screen_exited.connect(delete_projectile);

func _process(delta: float) -> void:
	global_position += transform.x * delta * speed * 100;

## Delete this projectile once it's offscreen
func delete_projectile(body: Node2D) -> void:
	if body is TileMapLayer:
		queue_free();
