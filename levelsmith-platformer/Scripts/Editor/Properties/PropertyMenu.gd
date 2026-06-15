extends Panel

# Entity currently selected for editing
var selectedEntity: Node2D;

# Name displayed on property menu
@export var entityName: Label;

@export var playerMenu: VBoxContainer;
@export var patrollingMenu: VBoxContainer;
@export var flyingMenu: VBoxContainer;

# Player values
var playerSpeed: float;
var playerJumpHeight : float;
var playerAirControl : float;
var playerFallSpeed : float;
var playerCoyoteTime : float;

# Player value sliders
@export var playerSpeedSlider: VBoxContainer;
@export var playerJumpSlider: VBoxContainer;
@export var playerAirControlSlider: VBoxContainer;
@export var playerFallSpeedSlider: VBoxContainer;
@export var playerCoyoteTimeSlider: VBoxContainer;

# Patrolling inputs
@export var patrollingSpeedSlider: VBoxContainer;
@export var patrollingRestrictedCheckbox: VBoxContainer;

# Flying inputs
@export var flyingSpeedSlider: VBoxContainer;
@export var flyingOffsetXSlider: VBoxContainer;
@export var flyingOffsetYSlider: VBoxContainer;

# Preset Options
@export var presetOptions: OptionButton;
var selectedPreset: Resource;

var selectedPlayerPreset: Resource;

## When this starts, select the default option
func _ready() -> void:
	_on_preset_options_item_selected(0);

## Close the property menu and set the selected entity to null
func close() -> void:
	hide();
	selectedEntity = null;

func _process(delta: float) -> void:
	# If there is a selected entity, set the name in the property menu, otherwise close
	if (selectedEntity != null):
		entityName.text = selectedEntity.name;
	else:
		hide();


## When a preset option is selected, load that preset and set all values to that preset
## index: the index of the preset selected
func _on_preset_options_item_selected(index: int) -> void:
	selectedPlayerPreset = load("res://Resources/PlayerPresets/" + presetOptions.get_item_text(index) + ".tres")
	playerSpeed = selectedPlayerPreset.groundSpeed;
	playerJumpHeight = selectedPlayerPreset.jumpHeight;
	playerAirControl = selectedPlayerPreset.airControl;
	playerFallSpeed = selectedPlayerPreset.fallSpeed;
	playerCoyoteTime = selectedPlayerPreset.coyoteTime;
	update_sliders();

## Load and update the custom preset, then save its changes
func update_custom() -> void:
	var customPreset = load("res://Resources/PlayerPresets/Custom.tres");
	customPreset.groundSpeed = playerSpeed;
	customPreset.jumpHeight = playerJumpHeight;
	customPreset.airControl = playerAirControl;
	customPreset.fallSpeed = playerFallSpeed;
	customPreset.coyoteTime = playerCoyoteTime;
	ResourceSaver.save(customPreset, "res://Resources/PlayerPresets/Custom.tres");

## Update all sliders according to the values
func update_sliders() -> void:
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
		patrollingRestrictedCheckbox.value = selectedPreset.restricted;
		patrollingSpeedSlider.update_slider();
		patrollingRestrictedCheckbox.update_checkbox();

	if selectedEntity is EnemyFlyer:
		flyingSpeedSlider.value = selectedPreset.speed;
		flyingOffsetXSlider.value = selectedPreset.pointBOffset.x;
		flyingOffsetYSlider.value = selectedPreset.pointBOffset.y;
		flyingSpeedSlider.update_slider();
		flyingOffsetXSlider.update_slider();
		flyingOffsetYSlider.update_slider();

## Update all of the player values based on the sliders
func update_values() -> void:
	playerSpeed = playerSpeedSlider.value;
	playerJumpHeight = playerJumpSlider.value;
	playerAirControl = playerAirControlSlider.value;
	playerFallSpeed = playerFallSpeedSlider.value;
	playerCoyoteTime = playerCoyoteTimeSlider.value;
	
	if selectedEntity is EnemyPatrol:
		selectedPreset.groundSpeed = patrollingSpeedSlider.value;
		selectedPreset.restricted = patrollingRestrictedCheckbox.value;
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres");
	
	if selectedEntity is EnemyFlyer:
		selectedPreset.speed = flyingSpeedSlider.value;
		selectedPreset.pointBOffset = Vector2(flyingOffsetXSlider.value, flyingOffsetYSlider.value);
		print(selectedPreset.pointBOffset)
		ResourceSaver.save(selectedPreset, "res://Resources/Enemies/" + selectedEntity.name + ".tres")

## When the slider is finished dragging, update the custom preset and switch to this preset
func _on_drag_ended() -> void:
	print("DRAG ENDED")
	update_values();
	if selectedEntity is Player:
		update_custom();
		presetOptions.select(4);
		_on_preset_options_item_selected(4);
	
func show_menu(resource: Resource = null) -> void:
	playerMenu.hide();
	patrollingMenu.hide();
	flyingMenu.hide();
	if selectedEntity is EnemyPatrol:
		selectedPreset = resource;
		update_sliders();
		patrollingMenu.show();
	elif selectedEntity is EnemyFlyer:
		selectedPreset = resource;
		update_sliders();
		flyingMenu.show();
	else:
		playerMenu.show();
