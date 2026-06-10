extends Area2D

@export var onScreen : VisibleOnScreenEnabler2D;

#var direction : float;
var speed : float;

func _ready() -> void:
	body_entered.connect(delete_projectile);
	area_entered.connect(_on_area_entered);
	onScreen.screen_exited.connect(delete_projectile);

func _process(delta: float) -> void:
	global_position += transform.x * delta * speed * 100;

## Delete this projectile once it's offscreen
func delete_projectile(body: Node2D = null) -> void:
	if body == null:
		queue_free();
	elif body is TileMapLayer:
		queue_free();


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("Player"):
		area.get_parent().take_damage(1);
