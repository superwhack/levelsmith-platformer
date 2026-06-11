extends Control

# Master manager
@export var masterManager: Node2D;

# Main menu buttons
@export var buttonNewLevel: Button;
@export var buttonImportLevel: Button;
@export var buttonLoadExample: Button;
@export var buttonQuit: Button;

# Overlays
@export var overlayNewLevel: ColorRect;
@export var overlayImportLevel: ColorRect;

# New level overlay children
@export var buttonNewLevelCreate: Button;
@export var buttonNewLevelCancel: Button;
@export var fieldNewLevelName: LineEdit;
@export var fieldNewLevelX: LineEdit;
@export var fieldNewLevelY: LineEdit;

# Import level overlay children
@export var buttonImportLevelCancel: Button;
@export var buttonImportLevelOpen: Button;
@export var buttonImportLevelBrowse: TextureButton;
@export var fieldImportLevelPath: LineEdit;
@export var panelInvalidPath: PanelContainer;

var fileExplorer: FileDialog;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlayImportLevel.hide();
	overlayNewLevel.hide();
	panelInvalidPath.hide();
	
	fileExplorer = FileDialog.new();
	add_child(fileExplorer);

	fileExplorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	fileExplorer.access = FileDialog.ACCESS_FILESYSTEM;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# New level overlay
	if (buttonNewLevel.button_pressed):
		overlayNewLevel.show();
	# create
	if (buttonNewLevelCreate.button_pressed):
		masterManager.edit();
	# cancel
	elif (buttonNewLevelCancel.button_pressed):
		overlayNewLevel.hide();
		
	# Import level button overlay
	if (buttonImportLevel.button_pressed):
		overlayImportLevel.show();
	# open
	if (buttonImportLevelOpen.button_pressed):
		panelInvalidPath.show();
	# cancel
	elif (buttonImportLevelCancel.button_pressed):
		overlayImportLevel.hide();
		panelInvalidPath.hide();
	# browse
	elif (buttonImportLevelBrowse.button_pressed):
		fileExplorer.popup_centered();
	
	# Quit button
	if (buttonQuit.button_pressed):
		get_tree().quit();
	
	
