extends Panel

# Entity currently selected for editing
var selectedEntity: Node2D;

# Name displayed on property menu
@export var entityName: Label;

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
