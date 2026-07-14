extends Panel

# Entity currently selected for editing
var selectedEntity : Node2D;

# Need an editor manager export to set unsavedChanges
@export var editorManager : Node2D;

# Name displayed on property menu
@export var entityName : Label;

@export var playerMenu : VBoxContainer;
@export var patrollingMenu : MarginContainer;
@export var shootingMenu : MarginContainer;
@export var flyingMenu : VBoxContainer;
@export var stationaryMenu : MarginContainer;
@export var movingPlatformMenu : MarginContainer;

# Player values
var playerHealth: int;
var playerSpeed: float;
var playerAcceleration: float;
var playerDeceleration: float;
var playerJumpHeight : float;
var playerAirControl : float;
var playerGravity : float;
var playerCoyoteTime : float;
var playerSlopeSlowdown : bool;
var playerOneways : bool;
var playerDoubleJump : bool;
var playerWallJump : bool;
var playerWallJumpDecay : bool;

# Player value sliders
@export var playerHealthSlider: VBoxContainer;
@export var playerSpeedSlider: VBoxContainer;
@export var playerAccelerationSlider : VBoxContainer;
@export var playerDecelerationSlider : VBoxContainer;
@export var playerJumpSlider: VBoxContainer;
@export var playerAirControlSlider: VBoxContainer;
@export var playerGravitySlider: VBoxContainer;
@export var playerCoyoteTimeSlider: VBoxContainer;
@export var playerSlopeSlowdownCheckbox : VBoxContainer;
@export var playerOnewaysCheckbox : VBoxContainer;
@export var playerDoubleJumpCheckbox: VBoxContainer;
@export var playerWallJumpCheckbox: VBoxContainer;
@export var playerWallJumpDecayCheckbox : VBoxContainer;

# Patrolling inputs
@export var patrollingSpeedSlider : VBoxContainer;
@export var patrollingDirectionDropdown : VBoxContainer;
@export var patrollingRestrictedCheckbox : VBoxContainer;

# Shooting inputs
@export var shootingDirectionSlider : VBoxContainer;
@export var shootingRandomDirection : VBoxContainer;
@export var shootingShotSpeedSlider : VBoxContainer;
@export var shootingFireRateSlider : VBoxContainer;
@export var shootingProjectileBounce : VBoxContainer;
@export var shootingGravity : VBoxContainer;

# Flying inputs
@export var flyingSpeedSlider : VBoxContainer;
@export var flyingOffsetXSlider : VBoxContainer;
@export var flyingOffsetYSlider : VBoxContainer;
var previewLine: Line2D;

# Stationary inputs
@export var stationaryDirectionDropdown : VBoxContainer;
@export var stationaryGravity : VBoxContainer;

# Moving platform inputs
@export var movingPlatformSpeedSlider : VBoxContainer;
@export var movingPlatformOffsetXSlider : VBoxContainer;
@export var movingPlatformOffsetYSlider : VBoxContainer;
@export var movingPlatformProgressSlider : VBoxContainer;

# Preset Options
@export var presetOptions : OptionButton;
var selectedPreset : Resource;

var selectedPlayerPreset : Resource;

# Direction arrow for shooting and patrolling enemies
var directionArrow : Sprite2D;

@export var closeButton : Button;

## When this starts, select the default option
func _ready() -> void:
	_on_preset_options_item_selected(0);
	
	playerHealthSlider.drag_ended.connect(_on_drag_ended);
	playerSpeedSlider.drag_ended.connect(_on_drag_ended);
	playerAccelerationSlider.drag_ended.connect(_on_drag_ended);
	playerDecelerationSlider.drag_ended.connect(_on_drag_ended);
	playerJumpSlider.drag_ended.connect(_on_drag_ended);
	playerAirControlSlider.drag_ended.connect(_on_drag_ended);
	playerGravitySlider.drag_ended.connect(_on_drag_ended);
	playerCoyoteTimeSlider.drag_ended.connect(_on_drag_ended);
	playerOnewaysCheckbox.check_changed.connect(_on_drag_ended);
	playerSlopeSlowdownCheckbox.check_changed.connect(_on_drag_ended);
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
	
	stationaryDirectionDropdown.dropdown_changed.connect(update_values);
	stationaryGravity.check_changed.connect(update_values);
	
	movingPlatformSpeedSlider.drag_ended.connect(_on_drag_ended);
	movingPlatformOffsetXSlider.drag_ended.connect(_on_drag_ended);
	movingPlatformOffsetYSlider.drag_ended.connect(_on_drag_ended);
	movingPlatformProgressSlider.drag_ended.connect(_on_drag_ended);
	
	closeButton.pressed.connect(close);

## Close the property menu and set the selected entity to null
func close() -> void:
	if directionArrow:
		directionArrow.scale = Vector2(1,1);
		directionArrow = null;
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
	elif selectedEntity is EnemyShooting:
		entityName.text = "Shooting Enemy";
		selectedEntity.adjust_arrow(-shootingDirectionSlider.value, shootingRandomDirection.value);
	elif selectedEntity is EnemyFlyer:
		entityName.text = "Flying Enemy";
		selectedEntity.previewLine.update(Vector2(flyingOffsetXSlider.value, flyingOffsetYSlider.value));
	elif selectedEntity is EnemyStationary:
		entityName.text = "Stationary Enemy";
		selectedEntity.update_flipped(!stationaryDirectionDropdown.value);
	elif selectedEntity is MovingPlatform:
		entityName.text = "Moving Platform";
		selectedEntity.adjust_preview(Vector2(movingPlatformOffsetXSlider.value, movingPlatformOffsetYSlider.value) * Global.TILE_SIZE, movingPlatformProgressSlider.value);
		selectedEntity.previewLine.update(Vector2(movingPlatformOffsetXSlider.value, movingPlatformOffsetYSlider.value));
	elif selectedEntity is Player:
		entityName.text = "Player";

## When a preset option is selected, load that preset and set all values to that preset
## index: the index of the preset selected
## update: If the sliders should be updated right after running
func _on_preset_options_item_selected(index: int) -> void:
	var presetType : String = presetOptions.get_item_text(index);
	if (presetType == "Custom"):
		selectedPlayerPreset = load("user://Resources/Custom.tres");
	else:
		selectedPlayerPreset = load("res://Resources/PlayerPresets/" + presetType + ".tres");
	
	playerHealth = selectedPlayerPreset.health;
	playerSpeed = selectedPlayerPreset.groundSpeed;
	playerAcceleration = selectedPlayerPreset.acceleration;
	playerDeceleration = selectedPlayerPreset.deceleration;
	playerJumpHeight = selectedPlayerPreset.jumpHeight;
	playerAirControl = selectedPlayerPreset.airControl;
	playerGravity = selectedPlayerPreset.fallSpeed;
	playerCoyoteTime = selectedPlayerPreset.coyoteTime;
	playerSlopeSlowdown = selectedPlayerPreset.slopeSlowdown;
	playerOneways = selectedPlayerPreset.oneways;
	playerDoubleJump = selectedPlayerPreset.doubleJump;
	playerWallJump = selectedPlayerPreset.wallJump;
	playerWallJumpDecay = selectedPlayerPreset.wallJumpDecay;
	update_sliders();

## Reset the Custom to conform with the Default on creating new levels
func reset_custom() -> void:
	var defaultPreset : Resource = load("res://Resources/PlayerPresets/Default.tres");
	var resetedCustom = defaultPreset.duplicate(true);
	ResourceSaver.save(resetedCustom, "user://Resources/Custom.tres");
	presetOptions.select(0);
	_on_preset_options_item_selected(0);

## Load and update the custom preset, then save its changes
func update_custom() -> void:
	var customPreset = load("user://Resources/Custom.tres");
	customPreset.health = playerHealth;
	customPreset.groundSpeed = playerSpeed;
	customPreset.acceleration = playerAcceleration;
	customPreset.deceleration = playerDeceleration;
	customPreset.jumpHeight = playerJumpHeight;
	customPreset.airControl = playerAirControl;
	customPreset.fallSpeed = playerGravity;
	customPreset.coyoteTime = playerCoyoteTime;
	customPreset.slopeSlowdown = playerSlopeSlowdown;
	customPreset.oneways = playerOneways;
	customPreset.doubleJump = playerDoubleJump;
	customPreset.wallJump = playerWallJump;
	customPreset.wallJumpDecay = playerWallJumpDecay;
	ResourceSaver.save(customPreset, "user://Resources/Custom.tres");
	
	presetOptions.select(4);
	_on_preset_options_item_selected(4);


## Update all sliders according to the values
func update_sliders() -> void:
	# Player stats
	playerHealthSlider.value = playerHealth;
	playerHealthSlider.update_slider();
	playerSpeedSlider.value = playerSpeed;
	playerSpeedSlider.update_slider();
	playerAccelerationSlider.value = playerAcceleration;
	playerAccelerationSlider.update_slider();
	playerDecelerationSlider.value = playerDeceleration;
	playerDecelerationSlider.update_slider();
	playerJumpSlider.value = playerJumpHeight;
	playerJumpSlider.update_slider();
	playerAirControlSlider.value = playerAirControl;
	playerAirControlSlider.update_slider();
	playerGravitySlider.value = playerGravity;
	playerGravitySlider.update_slider();
	playerCoyoteTimeSlider.value = playerCoyoteTime;
	playerCoyoteTimeSlider.update_slider();
	playerSlopeSlowdownCheckbox.value = playerSlopeSlowdown;
	playerSlopeSlowdownCheckbox.update_checkbox();
	playerOnewaysCheckbox.value = playerOneways;
	playerOnewaysCheckbox.update_checkbox();
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
	elif selectedEntity is EnemyFlyer:
		flyingSpeedSlider.value = selectedPreset.speed;
		flyingOffsetXSlider.value = selectedPreset.pointBOffset.x / Global.TILE_SIZE;
		flyingOffsetYSlider.value = selectedPreset.pointBOffset.y / Global.TILE_SIZE;
		flyingSpeedSlider.update_slider();
		flyingOffsetXSlider.update_slider();
		flyingOffsetYSlider.update_slider();
	elif selectedEntity is EnemyStationary:
		stationaryDirectionDropdown.value = int(!selectedPreset.isFacingRight);
		stationaryGravity.value = selectedPreset.gravity;
		stationaryDirectionDropdown.update_dropdown();
		stationaryGravity.update_checkbox();
	elif selectedEntity is MovingPlatform:
		movingPlatformSpeedSlider.value = selectedPreset.speed;
		movingPlatformOffsetXSlider.value = selectedPreset.pointBOffset.x / Global.TILE_SIZE;
		movingPlatformOffsetYSlider.value = selectedPreset.pointBOffset.y / Global.TILE_SIZE;
		movingPlatformProgressSlider.value = selectedPreset.progress;
		movingPlatformSpeedSlider.update_slider();
		movingPlatformOffsetXSlider.update_slider();
		movingPlatformOffsetYSlider.update_slider();
		movingPlatformProgressSlider.update_slider();


## Alternate the ability for a property to be selected
## property: The property to change
## selectable: If it can be selected
func make_selectable(property: VBoxContainer, selectable: bool) -> void:
	property.enabled = selectable;
	if !selectable:
		property.modulate = Color(1, 1, 1, 0.5);
	else:
		property.modulate = Color(1, 1, 1, 1);

## Update all of the player values based on the sliders
func update_values() -> void:
	playerHealth = playerHealthSlider.value;
	playerSpeed = playerSpeedSlider.value;
	playerAcceleration = playerAccelerationSlider.value;
	playerDeceleration = playerDecelerationSlider.value;
	playerJumpHeight = playerJumpSlider.value;
	playerAirControl = playerAirControlSlider.value;
	playerGravity = playerGravitySlider.value;
	playerCoyoteTime = playerCoyoteTimeSlider.value;
	playerSlopeSlowdown = playerSlopeSlowdownCheckbox.value;
	playerOneways = playerOnewaysCheckbox.value;
	playerDoubleJump = playerDoubleJumpCheckbox.value;
	playerWallJump = playerWallJumpCheckbox.value;
	playerWallJumpDecay = playerWallJumpDecayCheckbox.value;
	
	if selectedEntity is EnemyPatrol:
		selectedPreset.groundSpeed = patrollingSpeedSlider.value;
		selectedPreset.direction = patrollingDirectionDropdown.value;
		selectedPreset.restricted = patrollingRestrictedCheckbox.value;
		ResourceSaver.save(selectedPreset, "user://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyShooting:
		selectedPreset.randomDirection = shootingRandomDirection.value;
		make_selectable(shootingDirectionSlider, !selectedPreset.randomDirection);
		selectedPreset.direction = -shootingDirectionSlider.value;
		selectedPreset.shotSpeed = shootingShotSpeedSlider.value;
		selectedPreset.fireRate = shootingFireRateSlider.value;
		selectedPreset.projBounce = shootingProjectileBounce.value;
		selectedPreset.gravity = shootingGravity.value
		ResourceSaver.save(selectedPreset, "user://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyFlyer:
		selectedPreset.speed = flyingSpeedSlider.value;
		selectedPreset.pointBOffset = Vector2(flyingOffsetXSlider.value * Global.TILE_SIZE, flyingOffsetYSlider.value * Global.TILE_SIZE);
		ResourceSaver.save(selectedPreset, "user://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyStationary:
		selectedPreset.isFacingRight = !stationaryDirectionDropdown.value;
		selectedPreset.gravity = stationaryGravity.value;
		ResourceSaver.save(selectedPreset, "user://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is MovingPlatform:
		selectedPreset.speed = movingPlatformSpeedSlider.value;
		selectedPreset.pointBOffset = Vector2(movingPlatformOffsetXSlider.value * Global.TILE_SIZE, movingPlatformOffsetYSlider.value * Global.TILE_SIZE);
		selectedPreset.progress = movingPlatformProgressSlider.value;
		ResourceSaver.save(selectedPreset, "user://Resources/Enemies/" + selectedEntity.name + ".tres");
	

## When the slider is finished dragging, update the custom preset and switch to this preset
func _on_drag_ended() -> void:
	# Processframe is needed here so that when using the text input on the player, it actually correctly updates, add more if this becomes a problem again.
	await get_tree().process_frame;
	update_values();
	if selectedEntity is Player:
		update_custom();
	editorManager.unsavedChanges = true;

## Show the property menu, different sections pop up depending on the currently selected entity type
## resource: The resource file to load with properties
func show_menu(resource: Resource = null) -> void:
	show();
	if directionArrow:
		directionArrow.scale = Vector2(1,1);
		directionArrow = null;
	playerMenu.hide();
	patrollingMenu.hide();
	shootingMenu.hide();
	flyingMenu.hide();
	stationaryMenu.hide();
	movingPlatformMenu.hide();
	if selectedEntity is Enemy || selectedEntity is MovingPlatform:
		selectedPreset = resource;
		update_sliders();
		if selectedEntity is EnemyPatrol:
			directionArrow = selectedEntity.directionArrow;
			directionArrow.scale = Vector2(2,2);
			patrollingMenu.show();
		elif selectedEntity is EnemyShooting:
			directionArrow = selectedEntity.directionArrow;
			directionArrow.scale = Vector2(2,2);
			make_selectable(shootingDirectionSlider, !selectedPreset.randomDirection);
			shootingMenu.show();
		elif selectedEntity is EnemyFlyer:
			flyingMenu.show()
			previewLine = selectedEntity.previewLine;
			if previewLine:
				selectedEntity.previewLine.update(Vector2(flyingOffsetXSlider.value, flyingOffsetYSlider.value));
		elif selectedEntity is EnemyStationary:
			stationaryMenu.show();
		elif selectedEntity is MovingPlatform:
			movingPlatformMenu.show();
			previewLine = selectedEntity.previewLine;
			if previewLine:
				selectedEntity.previewLine.update(Vector2(movingPlatformOffsetXSlider.value, movingPlatformOffsetYSlider.value));
		
		
	else:
		playerMenu.show();
