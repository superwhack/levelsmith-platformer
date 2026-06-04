extends Button
class_name AssetItem;
@export var displayName: String;
@export var assetName: String;

enum AssetType { IMAGE, ANIMATION, AUDIO };
@export var type: AssetType;

signal item_selected(selectedItem: AssetItem);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = assetName;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_pressed() -> void:
	modulate = Color(0, 0, 0, 1)
	item_selected.emit(self);

func on_focus_exited() -> void:
	modulate = Color(1, 1 , 1, 1);
