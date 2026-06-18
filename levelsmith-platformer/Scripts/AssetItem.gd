extends Button
class_name AssetItem;
@export var displayName: String;
@export var assetName: String;

enum AssetType { IMAGE, ANIMATION, AUDIO };
@export var type: AssetType;

signal item_selected(selectedItem: AssetItem);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = displayName;
	pressed.connect(item_selected.emit);
	focus_exited.connect(on_focus_exited);

func on_focus_exited() -> void:
	modulate = Color(1, 1 , 1, 1);
