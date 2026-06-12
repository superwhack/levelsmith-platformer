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
@export var spinBoxNewLevelX: SpinBox;
@export var spinBoxNewLevelY: SpinBox;

# Import level overlay children
@export var buttonImportLevelCancel: Button;
@export var buttonImportLevelOpen: Button;
@export var buttonImportLevelBrowse: TextureButton;
@export var fieldImportLevelPath: LineEdit;
@export var panelInvalidPath: PanelContainer;

@export var fileExplorer: FileDialog;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlayImportLevel.hide();
	overlayNewLevel.hide();
	panelInvalidPath.hide();
	
	buttonNewLevel.pressed.connect( overlayNewLevel.show );
	buttonNewLevelCreate.pressed.connect( create_new_level );
	buttonNewLevelCancel.pressed.connect( overlayNewLevel.hide );
	
	buttonImportLevel.pressed.connect( overlayImportLevel.show );
	buttonImportLevelOpen.pressed.connect( import_level );
	buttonImportLevelCancel.pressed.connect( import_cancel );
	buttonImportLevelBrowse.pressed.connect( fileExplorer.popup_file_dialog );
	
	buttonQuit.pressed.connect( exit_program )
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
func import_level() -> void:
	panelInvalidPath.show();
		
func import_cancel() -> void:
	overlayImportLevel.hide();
	panelInvalidPath.hide();
		
func create_new_level() -> void:
	if ( fieldNewLevelName.text.strip_edges().is_empty() ):
		print( "Level has no name." );
		return;
	masterManager.level_setup( fieldNewLevelName.text, 
								Vector2i( 
									int(spinBoxNewLevelX.value), 
									int(spinBoxNewLevelY.value) ) 
								);

func exit_program() -> void:
	get_tree().quit();
		
