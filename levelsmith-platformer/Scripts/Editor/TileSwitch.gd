extends HBoxContainer

# Reference to tool manager
@export var toolManager : Node2D;
@export var editorManager : Node2D;

# References to button bars
@export var tiles : PanelContainer;
@export var entities : PanelContainer;

# References to tabs in Entity picker
@export var entityTab : HBoxContainer;
@export var propTab : HBoxContainer;

@export var tileMap : TileMapLayer;

# Misc object references
@export var entityPropDropdown : OptionButton;

## References to the tile button exports.
@export_group("Tile Button Exports")
@export var solidButton : Button;
@export var slopeButton : Button;
@export var oneWayButton : Button;
@export var bounceButton : Button;
@export var iceButton : Button;
@export var stickyButton : Button;
@export var hazardButton : Button;
@export var deathButton : Button;

## References to the entity button exports.
@export_group("Entity Button Exports")
@export var playerEntityButton : Button;
@export var coinEntityButton : Button;
@export var patrollingEntityButton : Button;
@export var stationaryEntityButton : Button;
@export var shootingEntityButton : Button;
@export var flyingEntityButton : Button;
@export var movingPlatformEntityButton : Button;
@export var goalEntityButton : Button;

## References to the prop button exports.
@export_group("Prop Button Exports")
@export var propOneButton : Button;
@export var propTwoButton : Button;
@export var propThreeButton : Button;
@export var propFourButton : Button;
@export var propFiveButton : Button;
@export var propSixButton : Button;


func _ready() -> void:
	entityPropDropdown.item_selected.connect(entity_dropdown_select);

## Toggles visibility of tile selection bar
## visibility: desired visibility
func display_tiles(visibility: bool):
	tiles.visible = visibility;

## Toggles visibility of entity selection bar
## visibility: desired visibility
func display_entities(visibility: bool):
	entities.visible = visibility;

## Toggles visibility of tabs
## index: index of tab selected
func entity_dropdown_select(index: int):
	AudioManager.play_UI_effect("UISelection");
	match index:
		0:
			editorManager.change_current_hotbar(Global.HotbarState.ENTITIES);
			toolManager.update_brush_object(Global.EntityType.PLAYER);
			toolManager.currentObjectRotation = 0;
			entityTab.visible = true;
			propTab.visible = false;
		1:
			editorManager.change_current_hotbar(Global.HotbarState.PROPS);
			toolManager.update_brush_object(Global.EntityType.PROP1);
			entityTab.visible = false;
			propTab.visible = true;
