extends HBoxContainer

# Export variables for different parts of the heart's visuals
@export var heartScene: PackedScene;
@export var fullHeartTexture: Texture2D;
@export var emptyHeartTexture: Texture2D;

# Hbox container holding all heart sprites
@export var healthContainer: HBoxContainer;

# Reference to player
var player: Player;

# Array storing all heart icons
var heartIcons: Array[TextureRect] = [];

## Binds the player reference to the player given
## newPlayer : Player that should now be referenced
func bind_player(newPlayer: Player) -> void:
	# If there is currently a player and it has the health changed signal connected, remove the signal
	if (player && player.healthChanged.is_connected(_on_player_health_changed)):
		player.healthChanged.disconnect(_on_player_health_changed);
	# Set the player reference to the given player
	player = newPlayer;
	if (!player):
		return;
	# If the player does not have the health changed signal connected, connect it
	if (!player.healthChanged.is_connected(_on_player_health_changed)):
		player.healthChanged.connect(_on_player_health_changed);
	# Sync to the player's values
	sync_to_player();

## Sync all important values to those of the player
func sync_to_player() -> void:
	# If there is no player, return
	if (!player):
		return;
	
	# Call all functions to display hearts based on the player's values
	clear_hearts();
	create_hearts(player.maxHealth);
	apply_health_visuals(player.health);

## Delete all currently shown and clear the array tracking them
func clear_hearts() -> void:
	for heart in heartIcons:
		heart.queue_free();
	heartIcons.clear();

## Creates an amount of hearts based on the count given
## count : Amount of hearts to be created, likely based on the player's max health
func create_hearts(count: int) -> void:
	# If there is no heart scene, return to prevent crashing
	if (heartScene == null):
		return;
	# Create hearts based on the count given and add them to the heartIcons array
	for i in range(count):
		var heart := heartScene.instantiate() as TextureRect;
		healthContainer.add_child(heart);
		heartIcons.append(heart);

## When the player health is changed, apply the health visuals with the new health
## newHealth : The amount of health the player now has
func _on_player_health_changed(newHealth: int) -> void:
	apply_health_visuals(newHealth);

## Apply the health visuals to be based on the current health
## currentHealth : The health the the visuals are being applied based on
func apply_health_visuals(currentHealth: int) -> void:
	# If the player is not being referenced, return
	if (!player):
		return;
	# Loop through all heart icons, set them visible and set their texture based on whether they are currently full or not
	for i in range(heartIcons.size()):
		heartIcons[i].visible = true;
		
		if i < currentHealth:
			heartIcons[i].texture = fullHeartTexture;
		else:
			heartIcons[i].texture = emptyHeartTexture;
