extends Button
class_name AssetItem;

# Exported variable for display and asset names.
@export var displayName: String;
@export var assetName: String;

# Enum for the type of asset being modified.
enum AssetType { IMAGE, ANIMATION, AUDIO };
@export var type: AssetType;

# An signal for when an item is chosen.
signal item_selected(selectedItem: AssetItem);

## Set the text and connect appropriate signals on ready.
func _ready() -> void:
	text = displayName;
	pressed.connect(item_selected.emit);
	focus_exited.connect(on_focus_exited);

## When the asset item is unfocused, reset the modulate.
func on_focus_exited() -> void:
	modulate = Color(1, 1 , 1, 1);
