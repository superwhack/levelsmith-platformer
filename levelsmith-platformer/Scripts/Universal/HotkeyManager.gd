extends Node

## References to other nodes
@export var editorManager : Node2D
@export var toolManager : Node2D
@export var entityManager : Node2D;
@export var tileSwitch : BoxContainer;

## Handles keyboard inputs.
## event: The input event to parse.
func _unhandled_key_input(event : InputEvent) -> void:
	if event.is_action_pressed("rotate"):
		toolManager.rotate_object();
	if event.is_action_pressed("toggle-background"):
		toolManager.isBackground = !toolManager.isBackground;
	
	# Switching Tools
	if event.is_action_pressed("brush-tool"):
		if (toolManager.prevBrushObject != -1):
			entityManager.drop_entity();
		toolManager.change_tool(Global.Tool.BRUSH);
		editorManager.change_current_hotbar(Global.HotbarState.TILES);
	elif event.is_action_pressed("box-brush-tool"):
		if (toolManager.prevBrushObject != -1):
			entityManager.drop_entity();
		toolManager.change_tool(Global.Tool.BOX_BRUSH);
		editorManager.change_current_hotbar(Global.HotbarState.TILES);
	elif event.is_action_pressed("cursor-tool"):
		toolManager.change_tool(Global.Tool.CURSOR);
		
		# Selected id is 0 for entities and 1 for props;
		var dropdownState = tileSwitch.entityPropDropdown.get_selected_id();
		editorManager.change_current_hotbar(dropdownState + 1);
	
	# Tile/Entity hotkeys
	match(editorManager.currentHotbarState):
		Global.HotbarState.TILES:
			if event.is_action_pressed("first-select"):
				tileSwitch.firstTileButton.select();
			elif event.is_action_pressed("second-select"):
				tileSwitch.secondTileButton.select();
			elif event.is_action_pressed("third-select"):
				tileSwitch.thirdTileButton.select();
			elif event.is_action_pressed("fourth-select"):
				tileSwitch.fourthTileButton.select();
			elif event.is_action_pressed("fifth-select"):
				tileSwitch.fifthTileButton.select();
			elif event.is_action_pressed("sixth-select"):
				tileSwitch.sixthTileButton.select();
			elif event.is_action_pressed("seventh-select"):
				tileSwitch.seventhTileButton.select();
			elif event.is_action_pressed("eighth-select"):
				tileSwitch.eighthTileButton.select();
		Global.HotbarState.ENTITIES:
			if event.is_action_pressed("first-select"):
				tileSwitch.firstEntityButton.select();
			elif event.is_action_pressed("second-select"):
				tileSwitch.secondEntityButton.select();
			elif event.is_action_pressed("third-select"):
				tileSwitch.thirdEntityButton.select();
			elif event.is_action_pressed("fourth-select"):
				tileSwitch.fourthEntityButton.select();
			elif event.is_action_pressed("fifth-select"):
				tileSwitch.fifthEntityButton.select();
			elif event.is_action_pressed("sixth-select"):
				tileSwitch.sixthEntityButton.select();
			elif event.is_action_pressed("seventh-select"):
				tileSwitch.seventhEntityButton.select();
			elif event.is_action_pressed("eighth-select"):
				tileSwitch.eighthEntityButton.select();
		Global.HotbarState.PROPS:
			if event.is_action_pressed("first-select"):
				tileSwitch.firstPropButton.select();
			elif event.is_action_pressed("second-select"):
				tileSwitch.secondPropButton.select();
			elif event.is_action_pressed("third-select"):
				tileSwitch.thirdPropButton.select();
			elif event.is_action_pressed("fourth-select"):
				tileSwitch.fourthPropButton.select();
			elif event.is_action_pressed("fifth-select"):
				tileSwitch.fifthPropButton.select();
			elif event.is_action_pressed("sixth-select"):
				tileSwitch.sixthPropButton.select();
