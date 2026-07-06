extends HBoxContainer

@export var heart_scene: PackedScene;
@export var empty_heart_modulate: Color = Color(0.55, 0.55, 0.55, 1.0);

@onready var health_container: HBoxContainer = $PanelContainer/MarginContainer/HealthContainer;

var player: Player;
var heart_icons: Array[TextureRect] = [];

func _ready() -> void:
	pass;

func bind_player(new_player: Player) -> void:
	if player and player.healthChanged.is_connected(_on_player_health_changed):
		player.healthChanged.disconnect(_on_player_health_changed)

	player = new_player
	if not player:
		return

	if not player.healthChanged.is_connected(_on_player_health_changed):
		player.healthChanged.connect(_on_player_health_changed)

	_sync_to_player()

func _sync_to_player() -> void:
	if not player:
		return
	
	_clear_hearts();
	_create_hearts(player.maxHealth);
	_apply_health_visuals(player.health)

func _clear_hearts() -> void:
	for heart in heart_icons:
		heart.queue_free();
	heart_icons.clear();

func _create_hearts(count: int) -> void:
	if heart_scene == null:
		return;
	
	for i in range(count):
		var heart := heart_scene.instantiate() as TextureRect;
		health_container.add_child(heart);
		heart_icons.append(heart);

func _on_player_health_changed(new_health: int) -> void:
	_apply_health_visuals(new_health)

func _apply_health_visuals(current_health: int) -> void:
	if not player:
		return

	for i in range(heart_icons.size()):
		heart_icons[i].visible = true
		heart_icons[i].modulate = Color.WHITE if i < current_health else empty_heart_modulate
