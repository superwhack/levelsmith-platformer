extends Control

# A reference to our continue button
@export var continueButton : Button;

# A reference to our richtextlabel
@export var body : RichTextLabel;

# A reference to our overlay
@export var subViewportContainer : SubViewportContainer;

# Timer for the shader tween.
var shaderTweenTime : float = 0.35;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body.meta_clicked.connect(_richtextlabel_on_meta_clicked);
	continueButton.pressed.connect(close_popup);

## Closes the web popup.
func close_popup() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(
		subViewportContainer.material,
		"shader_parameter/progress",
		0.0,
		shaderTweenTime
	);
	await tween.finished;
	queue_free();


## Opens the clicked link. From Godot documentation.
## meta: the meta link.
func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta));
