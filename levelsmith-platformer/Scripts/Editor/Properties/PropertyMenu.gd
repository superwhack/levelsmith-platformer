extends Panel

# Entity currently selected for editing
var selectedEntity : Node2D;

# Name displayed on property menu
@export var entityName : Label;

@export var playerMenu : VBoxContainer;
@export var flyingMenu : VBoxContainer;
@export var movingPlatformMenu : MarginContainer;
@export var patrollingMenu : MarginContainer;
@export var shootingMenu : MarginContainer;

# Player values
var playerHealth: int;
var playerSpeed: float;
var playerJumpHeight : float;
var playerAirControl : float;
var playerFallSpeed : float;
var playerCoyoteTime : float;
var playerDoubleJump : bool;
var playerWallJump : bool;
var playerWallJumpDecay : bool;

# Player value sliders
@export var playerHealthSlider: VBoxContainer;
@export var playerSpeedSlider: VBoxContainer;
@export var playerJumpSlider: VBoxContainer;
@export var playerAirControlSlider: VBoxContainer;
@export var playerFallSpeedSlider: VBoxContainer;
@export var playerCoyoteTimeSlider: VBoxContainer;
@export var playerDoubleJumpCheckbox: VBoxContainer;
@export var playerWallJumpCheckbox: VBoxContainer;
@export var playerWallJumpDecayCheckbox : VBoxContainer;

# Patrolling inputs
@export var patrollingSpeedSlider : VBoxContainer;
@export var patrollingDirectionDropdown : VBoxContainer;
@export var patrollingRestrictedCheckbox : VBoxContainer;

# Flying inputs
@export var flyingSpeedSlider : VBoxContainer;
@export var flyingOffsetXSlider : VBoxContainer;
@export var flyingOffsetYSlider : VBoxContainer;
var previewLine: Line2D;

# Moving platform inputs
@export var movingPlatformSpeedSlider : VBoxContainer;
@export var movingPlatformOffsetXSlider : VBoxContainer;
@export var movingPlatformOffsetYSlider : VBoxContainer;
@export var movingPlatformProgressSlider : VBoxContainer;

# Shooting inputs
@export var shootingDirectionSlider : VBoxContainer;
@export var shootingRandomDirection : VBoxContainer;
@export var shootingShotSpeedSlider : VBoxContainer;
@export var shootingFireRateSlider : VBoxContainer;
@export var shootingProjectileBounce : VBoxContainer;
@export var shootingGravity : VBoxContainer;

# Preset Options
@export var presetOptions : OptionButton;
var selectedPreset : Resource;

var selectedPlayerPreset : Resource;

# Direction arrow for shooting and patrolling enemies
var shootingDirectionArrow : Sprite2D;

@export var closeButton : Button;

## When this starts, select the default option
func _ready() -> void:
	_on_preset_options_item_selected(0);
	
	playerHealthSlider.drag_ended.connect(_on_drag_ended);
	playerSpeedSlider.drag_ended.connect(_on_drag_ended);
	playerJumpSlider.drag_ended.connect(_on_drag_ended);
	playerAirControlSlider.drag_ended.connect(_on_drag_ended);
	playerFallSpeedSlider.drag_ended.connect(_on_drag_ended);
	playerCoyoteTimeSlider.drag_ended.connect(_on_drag_ended);
	playerDoubleJumpCheckbox.check_changed.connect(_on_drag_ended);
	playerWallJumpCheckbox.check_changed.connect(_on_drag_ended);
	playerWallJumpDecayCheckbox.check_changed.connect(_on_drag_ended);
	presetOptions.item_selected.connect(_on_preset_options_item_selected);
	
	patrollingSpeedSlider.drag_ended.connect(_on_drag_ended);
	patrollingDirectionDropdown.dropdown_changed.connect(update_values);
	patrollingRestrictedCheckbox.check_changed.connect(update_values);
	
	shootingDirectionSlider.drag_ended.connect(_on_drag_ended);
	shootingRandomDirection.check_changed.connect(update_values);
	shootingShotSpeedSlider.drag_ended.connect(_on_drag_ended);
	shootingFireRateSlider.drag_ended.connect(_on_drag_ended);
	shootingProjectileBounce.check_changed.connect(update_values);
	shootingGravity.check_changed.connect(update_values);
	
	flyingSpeedSlider.drag_ended.connect(_on_drag_ended);
	flyingOffsetXSlider.drag_ended.connect(_on_drag_ended);
	flyingOffsetYSlider.drag_ended.connect(_on_drag_ended);
	
	movingPlatformSpeedSlider.drag_ended.connect(_on_drag_ended);
	movingPlatformOffsetXSlider.drag_ended.connect(_on_drag_ended);
	movingPlatformOffsetYSlider.drag_ended.connect(_on_drag_ended);
	movingPlatformProgressSlider.drag_ended.connect(_on_drag_ended);
	
	closeButton.pressed.connect(close);

## Close the property menu and set the selected entity to null
func close() -> void:
	if previewLine:
		previewLine.modulate.a = .5;
	if shootingDirectionArrow:
		shootingDirectionArrow.scale = Vector2(1,1);
		shootingDirectionArrow = null;
	hide();
	selectedEntity = null;

## Runs every frame. Sets the text and arrows when an entity is selected
## _delta: Time passed since the last frame
func _process(_delta: float) -> void:
	# If there is a selected entity, set the name in the property menu, otherwise close
	if (!selectedEntity):
		hide();
		return;
		
	if selectedEntity is EnemyPatrol:
		entityName.text = "Patrolling Enemy";
		selectedEntity.adjust_arrow(int(patrollingDirectionDropdown.value) * 180 + 90);
	elif selectedEntity is EnemyFlyer:
		entityName.text = "Flying Enemy";
		selectedEntity.update_line_preview(flyingOffsetXSlider.value, flyingOffsetYSlider.value);
		selectedEntity.previewLine.modulate.a = 1;
	elif selectedEntity is MovingPlatform:
		entityName.text = "Moving Platform";
		selectedEntity.adjust_preview(Vector2(movingPlatformOffsetXSlider.value, movingPlatformOffsetYSlider.value) * Global.TILE_SIZE, movingPlatformProgressSlider.value);
		selectedEntity.update_line_preview(movingPlatformOffsetXSlider.value, movingPlatformOffsetYSlider.value);
		selectedEntity.previewLine.modulate.a = 1;
	elif selectedEntity is EnemyShooting:
		entityName.text = "Shooting Enemy";
		selectedEntity.adjust_arrow(-shootingDirectionSlider.value + 90, shootingRandomDirection.value);
	elif selectedEntity is Player:
		entityName.text = "Player";

## When a preset option is selected, load that preset and set all values to that preset
## index: the index of the preset selected
func _on_preset_options_item_selected(index: int) -> void:
	selectedPlayerPreset = load("res://Resources/PlayerPresets/" + presetOptions.get_item_text(index) + ".tres")
	playerHealth = selectedPlayerPreset.health;
	playerSpeed = selectedPlayerPreset.groundSpeed;
	playerJumpHeight = selectedPlayerPreset.jumpHeight;
	playerAirControl = selectedPlayerPreset.airControl;
	playerFallSpeed = selectedPlayerPreset.fallSpeed;
	playerCoyoteTime = selectedPlayerPreset.coyoteTime;
	playerDoubleJump = selectedPlayerPreset.doubleJump;
	playerWallJump = selectedPlayerPreset.wallJump;
	playerWallJumpDecay = selectedPlayerPreset.wallJumpDecay;
	update_sliders();

## Reset the Custom to conform with the Default on creating new levels
func reset_custom() -> void:
	var defaultPreset : Resource = load("res://Resources/PlayerPresets/Default.tres");
	var resetedCustom = defaultPreset.duplicate(true);
	ResourceSaver.save(resetedCustom, "res://Resources/PlayerPresets/Custom.tres");
	presetOptions.select(0);
	_on_preset_options_item_selected(0);

## Load and update the custom preset, then save its changes
func update_custom() -> void:
	var customPreset = load("res://Resources/PlayerPresets/Custom.tres");
	customPreset.health = playerHealth;
	customPreset.groundSpeed = playerSpeed;
	customPreset.jumpHeight = playerJumpHeight;
	customPreset.airControl = playerAirControl;
	customPreset.fallSpeed = playerFallSpeed;
	customPreset.coyoteTime = playerCoyoteTime;
	customPreset.doubleJump = playerDoubleJump;
	customPreset.wallJump = playerWallJump;
	customPreset.wallJumpDecay = playerWallJumpDecay;
	ResourceSaver.save(customPreset, "res://Resources/PlayerPresets/Custom.tres");
	
	presetOptions.select(4);
	_on_preset_options_item_selected(4);

## Update all sliders according to the values
func update_sliders() -> void:
	# Player stats
	playerHealthSlider.value = playerHealth;
	playerHealthSlider.update_slider();
	playerSpeedSlider.value = playerSpeed;
	playerSpeedSlider.update_slider();
	playerJumpSlider.value = playerJumpHeight;
	playerJumpSlider.update_slider();
	playerAirControlSlider.value = playerAirControl;
	playerAirControlSlider.update_slider();
	playerFallSpeedSlider.value = playerFallSpeed;
	playerFallSpeedSlider.update_slider();
	playerCoyoteTimeSlider.value = playerCoyoteTime;
	playerCoyoteTimeSlider.update_slider();
	playerDoubleJumpCheckbox.value = playerDoubleJump;
	playerDoubleJumpCheckbox.update_checkbox();
	playerWallJumpCheckbox.value = playerWallJump;
	playerWallJumpCheckbox.update_checkbox();
	# Make the WallJumpDecay Checkbox transparent if it can't be selected.
	if !playerWallJump:
		playerWallJumpDecay = false;
	make_selectable(playerWallJumpDecayCheckbox, playerWallJump);
	playerWallJumpDecayCheckbox.value = playerWallJumpDecay;
	playerWallJumpDecayCheckbox.update_checkbox();
	# Enemies
	if selectedEntity is EnemyPatrol:
		patrollingSpeedSlider.value = selectedPreset.groundSpeed;
		patrollingDirectionDropdown.value = selectedPreset.direction;
		patrollingRestrictedCheckbox.value = selectedPreset.restricted;
		patrollingSpeedSlider.update_slider();
		patrollingDirectionDropdown.update_dropdown();
		patrollingRestrictedCheckbox.update_checkbox();
	elif selectedEntity is EnemyFlyer:
		flyingSpeedSlider.value = selectedPreset.speed;
		flyingOffsetXSlider.value = selectedPreset.pointBOffset.x / Global.TILE_SIZE;
		flyingOffsetYSlider.value = selectedPreset.pointBOffset.y / Global.TILE_SIZE;
		flyingSpeedSlider.update_slider();
		flyingOffsetXSlider.update_slider();
		flyingOffsetYSlider.update_slider();
	elif selectedEntity is MovingPlatform:
		movingPlatformSpeedSlider.value = selectedPreset.speed;
		movingPlatformOffsetXSlider.value = selectedPreset.pointBOffset.x / Global.TILE_SIZE;
		movingPlatformOffsetYSlider.value = selectedPreset.pointBOffset.y / Global.TILE_SIZE;
		movingPlatformProgressSlider.value = selectedPreset.progress;
		movingPlatformSpeedSlider.update_slider();
		movingPlatformOffsetXSlider.update_slider();
		movingPlatformOffsetYSlider.update_slider();
		movingPlatformProgressSlider.update_slider();
	elif selectedEntity is EnemyShooting:
		shootingDirectionSlider.value = -selectedPreset.direction;
		shootingRandomDirection.value = selectedPreset.randomDirection;
		shootingShotSpeedSlider.value = selectedPreset.shotSpeed;
		shootingFireRateSlider.value = selectedPreset.fireRate;
		shootingProjectileBounce.value = selectedPreset.projBounce;
		shootingGravity.value = selectedPreset.gravity;
		shootingDirectionSlider.update_slider();
		shootingRandomDirection.update_checkbox();
		shootingShotSpeedSlider.update_slider();
		shootingFireRateSlider.update_slider();
		shootingProjectileBounce.update_checkbox();
		shootingGravity.update_checkbox();

## Alternate the ability for a property to be selected
## property: The property to change
## selectable: If it can be selected
func make_selectable(property : VBoxContainer, selectable : bool) -> void:
	property.enabled = selectable;
	if !selectable:
		property.modulate = Color(1, 1, 1, 0.5);
	else:
		property.modulate = Color(1, 1, 1, 1);

## Update all of the player values based on the sliders
func update_values() -> void:
	playerHealth = playerHealthSlider.value;
	playerSpeed = playerSpeedSlider.value;
	playerJumpHeight = playerJumpSlider.value;
	playerAirControl = playerAirControlSlider.value;
	playerFallSpeed = playerFallSpeedSlider.value;
	playerCoyoteTime = playerCoyoteTimeSlider.value;
	playerDoubleJump = playerDoubleJumpCheckbox.value;
	playerWallJump = playerWallJumpCheckbox.value;
	playerWallJumpDecay = playerWallJumpDecayCheckbox.value;
	
	if selectedEntity is EnemyPatrol:
		selectedPreset.groundSpeed = patrollingSpeedSlider.value;
		selectedPreset.direction = patrollingDirectionDropdown.value;
		selectedPreset.restricted = patrollingRestrictedCheckbox.value;
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyFlyer:
		selectedPreset.speed = flyingSpeedSlider.value;
		selectedPreset.pointBOffset = Vector2(flyingOffsetXSlider.value * Global.TILE_SIZE, flyingOffsetYSlider.value * Global.TILE_SIZE);
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is MovingPlatform:
		selectedPreset.speed = movingPlatformSpeedSlider.value;
		selectedPreset.pointBOffset = Vector2(movingPlatformOffsetXSlider.value * Global.TILE_SIZE, movingPlatformOffsetYSlider.value * Global.TILE_SIZE);
		selectedPreset.progress = movingPlatformProgressSlider.value;
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyShooting:
		selectedPreset.randomDirection = shootingRandomDirection.value;
		make_selectable(shootingDirectionSlider, !selectedPreset.randomDirection);
		selectedPreset.direction = -shootingDirectionSlider.value;
		selectedPreset.shotSpeed = shootingShotSpeedSlider.value;
		selectedPreset.fireRate = shootingFireRateSlider.value;
		selectedPreset.projBounce = shootingProjectileBounce.value;
		selectedPreset.gravity = shootingGravity.value
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");

## When the slider is finished dragging, update the custom preset and switch to this preset
func _on_drag_ended() -> void:
	update_values();
	if selectedEntity is Player:
		update_custom();

## Show the property menu, different sections pop up depending on the currently selected entity type
## resource: The resource file to load with properties
func show_menu(resource: Resource = null) -> void:
	show();
	if previewLine:
		previewLine.modulate.a = .5;
	if shootingDirectionArrow:
		shootingDirectionArrow.scale = Vector2(1,1);
		shootingDirectionArrow = null;
	playerMenu.hide();
	patrollingMenu.hide();
	flyingMenu.hide();
	shootingMenu.hide();
	movingPlatformMenu.hide();
	if selectedEntity is Enemy || selectedEntity is MovingPlatform:
		selectedPreset = resource;
		update_sliders();
		if selectedEntity is EnemyPatrol:
			shootingDirectionArrow = selectedEntity.directionArrow;
			patrollingMenu.show();
		elif selectedEntity is EnemyFlyer:
			flyingMenu.show()
			previewLine = selectedEntity.previewLine;
			if previewLine:
				previewLine.modulate.a = 1;
				selectedEntity.update_line_preview(flyingOffsetXSlider.value, flyingOffsetYSlider.value);
		elif selectedEntity is MovingPlatform:
			movingPlatformMenu.show();
			previewLine = selectedEntity.previewLine;
			if previewLine:
				previewLine.modulate.a = 1;
				selectedEntity.update_line_preview(movingPlatformOffsetXSlider.value, movingPlatformOffsetYSlider.value)
		elif selectedEntity is EnemyShooting:
			shootingDirectionArrow = selectedEntity.directionArrow;
			shootingDirectionArrow.scale = Vector2(2,2);
			make_selectable(shootingDirectionSlider, !selectedPreset.randomDirection);
			shootingMenu.show();
	else:
		playerMenu.show();
