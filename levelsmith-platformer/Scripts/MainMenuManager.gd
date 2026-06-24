extends Control

# Master manager
@export var masterManager : Node2D;

# Main menu buttons
@export var buttonNewLevel : Button;
@export var buttonImportLevel : Button;
@export var buttonLoadExample : Button;
@export var buttonQuit : Button;

# Overlays
@export var overlayNewLevel : ColorRect;
@export var overlayImportLevel : ColorRect;

# New level overlay children
@export var buttonNewLevelCreate : Button;
@export var buttonNewLevelCancel : Button;
@export var fieldNewLevelName : LineEdit;
@export var spinBoxNewLevelX : SpinBox;
@export var spinBoxNewLevelY : SpinBox;

# Import level overlay children
@export var buttonImportLevelCancel : Button;
@export var buttonImportLevelOpen : Button;
@export var buttonImportLevelBrowse : TextureButton;
@export var fieldImportLevelPath : LineEdit;

@export var fileExplorer : FileDialog;
var importedLevelPath : String;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hides other screens
	overlayImportLevel.hide();
	overlayNewLevel.hide();
	
	# Connect signals
	buttonNewLevel.pressed.connect(overlayNewLevel.show);
	buttonNewLevelCreate.pressed.connect(create_new_level);
	buttonNewLevelCancel.pressed.connect(overlayNewLevel.hide);
	
	buttonImportLevel.pressed.connect(overlayImportLevel.show);
	buttonImportLevelOpen.pressed.connect(import_level);
	buttonImportLevelCancel.pressed.connect(import_cancel);
	buttonImportLevelBrowse.pressed.connect(fileExplorer.popup_file_dialog);
	
	buttonQuit.pressed.connect(exit_program);
	
	var set_directory = func (directory: String) -> void:
		importedLevelPath = directory;
		fieldImportLevelPath.text = importedLevelPath;
	
	fileExplorer.dir_selected.connect(set_directory);
	
## Called when import level button is pressed
## directory: 
func import_level() -> void:
	if (!ImportExportManager.validate_import(importedLevelPath)): return;
	
	ImportExportManager.clone_data(importedLevelPath + "/", "user://Levels/");
	masterManager.import_level_and_edit();
	overlayImportLevel.hide();
	pass;

## Called when import level is closed
func import_cancel() -> void:
	overlayImportLevel.hide();

## Opens the menu for setting a name and size for the level
func create_new_level() -> void:
	if ( fieldNewLevelName.text.strip_edges().is_empty() ):
		PopUpManager.create_error_popup("Creation Failed!", "Level has no name!");
		return;
	overlayNewLevel.hide();
	masterManager.level_setup( 
		fieldNewLevelName.text, 
		Vector2i( 
			int(spinBoxNewLevelX.value), 
			int(spinBoxNewLevelY.value) 
			) 
		);

## Exits the program
func exit_program() -> void:
	get_tree().quit();
