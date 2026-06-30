extends Panel

# Entity currently selected for editing
var selectedEntity : Node2D;

# Name displayed on property menu
@export var entityName : Label;

@export var playerMenu : VBoxContainer;
@export var flyingMenu : VBoxContainer;
@export var patrollingMenu : MarginContainer;
@export var shootingMenu : MarginContainer;
@export var stationaryMenu : VBoxContainer;

# Player values
var playerHealth: int;
var playerSpeed: float;
var playerJumpHeight : float;
var playerAirControl : float;
var playerFallSpeed : float;
var playerCoyoteTime : float;

# Player value sliders
@export var playerHealthSlider: VBoxContainer;
@export var playerSpeedSlider: VBoxContainer;
@export var playerJumpSlider: VBoxContainer;
@export var playerAirControlSlider: VBoxContainer;
@export var playerFallSpeedSlider: VBoxContainer;
@export var playerCoyoteTimeSlider: VBoxContainer;


# Patrolling inputs
@export var patrollingSpeedSlider : VBoxContainer;
@export var patrollingDirectionDropdown : VBoxContainer;
@export var patrollingRestrictedCheckbox : VBoxContainer;

# Flying inputs
@export var flyingSpeedSlider : VBoxContainer;
@export var flyingOffsetXSlider : VBoxContainer;
@export var flyingOffsetYSlider : VBoxContainer;
var previewLine: Line2D;

# Shooting inputs
@export var shootingDirectionSlider : VBoxContainer;
@export var shootingShotSpeedSlider : VBoxContainer;
@export var shootingFireRateSlider : VBoxContainer;
@export var shootingProjectileBounce : VBoxContainer;
@export var shootingGravity : VBoxContainer;

#Stationary Inputs
@export var directionFacing: VBoxContainer;
@export var gravityEnabled: VBoxContainer;

# Preset Options
@export var presetOptions : OptionButton;
var selectedPreset : Resource;

var selectedPlayerPreset : Resource;

# Direction arrow for shooting, patrolling, and stationary enemies
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
	presetOptions.item_selected.connect(_on_preset_options_item_selected);
	
	patrollingSpeedSlider.drag_ended.connect(_on_drag_ended);
	patrollingDirectionDropdown.dropdown_changed.connect(update_values);
	patrollingRestrictedCheckbox.check_changed.connect(update_values);
	
	shootingDirectionSlider.drag_ended.connect(_on_drag_ended);
	shootingShotSpeedSlider.drag_ended.connect(_on_drag_ended);
	shootingFireRateSlider.drag_ended.connect(_on_drag_ended);
	shootingProjectileBounce.check_changed.connect(update_values);
	shootingGravity.check_changed.connect(update_values);
	
	flyingSpeedSlider.drag_ended.connect(_on_drag_ended);
	flyingOffsetXSlider.drag_ended.connect(_on_drag_ended);
	flyingOffsetYSlider.drag_ended.connect(_on_drag_ended);
	
	#directionFacing.dropdown_changed.connect(update_values);
	gravityEnabled.check_changed.connect(update_values);
	
	closeButton.pressed.connect(close);

## Close the property menu and set the selected entity to null
func close() -> void:
	if previewLine:
		previewLine.hide()
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
	elif  selectedEntity is EnemyFlyer:
		entityName.text = "Flying Enemy";
	elif selectedEntity is EnemyShooting:
		entityName.text = "Shooting Enemy";
		selectedEntity.adjust_arrow(-shootingDirectionSlider.value + 90);
	elif selectedEntity is EnemyStationary:
		entityName.text = "Stationary Enemy";
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
	update_sliders();

## Load and update the custom preset, then save its changes
func update_custom() -> void:
	var customPreset = load("res://Resources/PlayerPresets/Custom.tres");
	customPreset.health = playerHealth;
	customPreset.groundSpeed = playerSpeed;
	customPreset.jumpHeight = playerJumpHeight;
	customPreset.airControl = playerAirControl;
	customPreset.fallSpeed = playerFallSpeed;
	customPreset.coyoteTime = playerCoyoteTime;
	ResourceSaver.save(customPreset, "res://Resources/PlayerPresets/Custom.tres");

## Update the preview for the flying enemy
func update_flying_preview() -> void:
	if selectedEntity == null:
		return;
	var offset : Vector2 = Vector2(flyingOffsetXSlider.value * Global.TILE_SIZE, flyingOffsetYSlider.value * Global.TILE_SIZE);
	previewLine.global_position = selectedEntity.global_position;
	previewLine.clear_points()
	previewLine.add_point(Vector2.ZERO)
	previewLine.add_point(offset)

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
	elif selectedEntity is EnemyShooting:
		shootingDirectionSlider.value = -selectedPreset.direction;
		shootingShotSpeedSlider.value = selectedPreset.shotSpeed;
		shootingFireRateSlider.value = selectedPreset.fireRate;
		shootingProjectileBounce.value = selectedPreset.projBounce;
		shootingGravity.value = selectedPreset.gravity;
		shootingDirectionSlider.update_slider();
		shootingShotSpeedSlider.update_slider();
		shootingFireRateSlider.update_slider();
		shootingProjectileBounce.update_checkbox();
		shootingGravity.update_checkbox();
	#elif selectedEntity is EnemyStationary:
		#directionFacing.value = selectedPreset.directionFacing;
		#directionFacing.update_dropdown();
		#gravityEnabled.value = selectedPreset.gravityEnabled;
		#gravityEnabled.update_checkbox();

## Update all of the player values based on the sliders
func update_values() -> void:
	playerHealth = playerHealthSlider.value;
	playerSpeed = playerSpeedSlider.value;
	playerJumpHeight = playerJumpSlider.value;
	playerAirControl = playerAirControlSlider.value;
	playerFallSpeed = playerFallSpeedSlider.value;
	playerCoyoteTime = playerCoyoteTimeSlider.value;
	
	if selectedEntity is EnemyPatrol:
		selectedPreset.groundSpeed = patrollingSpeedSlider.value;
		selectedPreset.direction = patrollingDirectionDropdown.value;
		selectedPreset.restricted = patrollingRestrictedCheckbox.value;
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyFlyer:
		selectedPreset.speed = flyingSpeedSlider.value;
		selectedPreset.pointBOffset = Vector2(flyingOffsetXSlider.value * Global.TILE_SIZE, flyingOffsetYSlider.value * Global.TILE_SIZE);
		update_flying_preview();
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");
	elif selectedEntity is EnemyShooting:
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
		presetOptions.select(4);
		_on_preset_options_item_selected(4);

## Show the property menu, different sections pop up depending on the currently selected entity type
## resource: The resource file to load with properties
func show_menu(resource: Resource = null) -> void:
	show();
	if shootingDirectionArrow:
		shootingDirectionArrow.scale = Vector2(1,1);
		shootingDirectionArrow = null;
	playerMenu.hide();
	patrollingMenu.hide();
	flyingMenu.hide();
	shootingMenu.hide();
	if selectedEntity is Enemy:
		selectedPreset = resource;
		update_sliders();
		if selectedEntity is EnemyPatrol:
			shootingDirectionArrow = selectedEntity.directionArrow;
			patrollingMenu.show();
		elif selectedEntity is EnemyFlyer:
			flyingMenu.show()
			previewLine = selectedEntity.previewLine
			if previewLine:
				previewLine.show()
				update_flying_preview()
		elif selectedEntity is EnemyShooting:
			shootingDirectionArrow = selectedEntity.directionArrow;
			shootingDirectionArrow.scale = Vector2(2,2);
			shootingMenu.show();
		elif selectedEntity is EnemyStationary:
			shootingDirectionArrow = selectedEntity.directionArrow;
			stationaryMenu.show();
	else:
		playerMenu.show();
