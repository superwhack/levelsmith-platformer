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
@export var firstTileButton : Button;
@export var secondTileButton : Button;
@export var thirdTileButton : Button;
@export var fourthTileButton : Button;
@export var fifthTileButton : Button;
@export var sixthTileButton : Button;
@export var seventhTileButton : Button;
@export var eighthTileButton : Button;

## References to the entity button exports.
@export_group("Entity Button Exports")
@export var firstEntityButton : Button;
@export var secondEntityButton : Button;
@export var thirdEntityButton : Button;
@export var fourthEntityButton : Button;
@export var fifthEntityButton : Button;
@export var sixthEntityButton : Button;
@export var seventhEntityButton : Button;
@export var eighthEntityButton : Button;

## References to the prop button exports.
@export_group("Prop Button Exports")
@export var firstPropButton : Button;
@export var secondPropButton : Button;
@export var thirdPropButton : Button;
@export var fourthPropButton : Button;
@export var fifthPropButton : Button;
@export var sixthPropButton : Button;


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
