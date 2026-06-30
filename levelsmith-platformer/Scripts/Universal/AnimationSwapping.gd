extends Node

@export var assetManager : AssetManager;

var filePath : String;

var selectedEntityType : String;

# The Texture that will be replacing the texture with the preview name
var animationPreviewToReplace : Texture2D;
var animationPreviewNameToReplace : String;

# The current animation index being viewed
var currentAnimationIndex : int = 0;

# The current frame the animation is on
var animationFrameIndex : int = 0;

var currentLoadedAnimation : Array[Texture2D];

@export var animationPreview : Panel;
@export var animationPreviewTexture : TextureRect;

# References to animation preview controls and visuals
@export var animationPreviewRightButton : Button;
@export var animationPreviewLeftButton : Button;
@export var animationName : Label;
@export var frameRightButton : Button;
@export var frameLeftButton : Button;
@export var frameCountLabel : Label;
@export var playButton : Button;
@export var stopButton : Button;
@export var FPSSpinbox : SpinBox;

# Information about played animation
var playingAnimation : bool;
var FPS : float = 12;
var animTimer : float = 0;

# All types of entities
var animatedEntityTypes : Array[String] = ["Player", "StationaryEnemy", "ShootingEnemy", "PatrollingEnemy", "FlyingEnemy"];

# Player Animations
var playerAnimations : Array[String] = ["PlayerRun", "PlayerJump", "PlayerIdle", "PlayerFall", "PlayerHurt", "PlayerDeath"];

# All Enemy Animations
var stationaryEnemyAnimations : Array[String] = ["StationaryIdle", "StationaryDeath"];
var patrollingEnemyAnimations : Array[String] = ["PatrolWalk", "PatrolDeath"];
var flyingEnemyAnimations : Array[String] = ["FlyMove", "FlyDeath"];
var shootingEnemyAnimations : Array[String] = ["EnemyShoot", "ShootIdle", "ShootDeath"];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animationPreviewRightButton.pressed.connect(anim_change.bind(true));
	animationPreviewLeftButton.pressed.connect(anim_change.bind(false));
	frameRightButton.pressed.connect(frame_change.bind(true));
	frameLeftButton.pressed.connect(frame_change.bind(false));
	playButton.pressed.connect(play_preview_animation);
	stopButton.pressed.connect(stop_preview_animation);
	FPSSpinbox.value_changed.connect(fps_updated);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		# Play the animation
	if (playingAnimation):
		animTimer += delta;
		if (animTimer >= 1/FPS):
			frame_change();
			animTimer = 0;

## Retrieve the frames for an animation from a given folder path
## folderName: Name of the folder to check
## Returns: Array of all frames for animation
func get_animation_from_folder(folderName: String) -> Array[Image]:
	# Get the path to the folder
	var pathToFolder : String = FileSearch.find_directory_by_name(folderName);
	# If the path is found, retrieve all files and add to array
	if (pathToFolder):
		var dir : DirAccess = DirAccess.open(pathToFolder);
		var allImageNames : PackedStringArray = dir.get_files();
		var allImages : Array[Image] = [];
		for imageName in allImageNames:
			allImages.append(assetManager.find_image(imageName));
		return allImages;
	else:
		PopUpManager.create_error_popup("Could not find folder","Could not find folder with name " + folderName + ".");
	return [];

## Replaces the currently previewed animation with one chosen via file dialog.
## newAnimationPath: The path to the folder selected
func replace_animation(newAnimationPath : String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(animationPreviewNameToReplace);
	var targetDirectory : DirAccess = assetManager.clear_image(animationPreviewNameToReplace);
	# Count for which file is being iterated at for naming purposes
	var fileCount : int = 0;
	# Loop through every file at the path
	for file in DirAccess.get_files_at(newAnimationPath):
		var currentFilePath = newAnimationPath + "/" + file;
		# If the file is a png, increase the file count and create a copy in the assets folder with its number
		if (file.get_extension().to_lower() == "png"):
			fileCount += 1;
			targetDirectory.copy(currentFilePath, str(targetFilePath, "/", animationPreviewNameToReplace, str(fileCount).pad_zeros(2), ".png"));
		else:
			if (!file.get_extension().to_lower() == "png.import"):
				PopUpManager.create_error_popup("File type incorrect", "File must be .png format.");
	
	# Replace the preview image if there is one, if not load default
	var replacementImage : Image = assetManager.find_image_in_folder(targetFilePath);
	if (replacementImage):
		currentLoadedAnimation.clear();
		for image in get_animation_from_folder(animationPreviewNameToReplace):
			currentLoadedAnimation.append(ImageTexture.create_from_image(image));
		update_animation_preview();
	else:
		PopUpManager.create_error_popup("No Defaults", "No default images yet, update this when there are default animations");

## Switch between animations within the entity
## next: Whether the user is switching to the next or previous animation
func anim_change(next : bool):
	# Pause the animation
	playingAnimation = false;
	# Increase or decrease the index accordingly
	if (next):
		currentAnimationIndex += 1;
	else:
		currentAnimationIndex -= 1;
	# Find the amount of animations the entity has
	var animationsCount : int = DirAccess.get_directories_at(FileSearch.find_directory_by_name(selectedEntityType)).size();
	# Clamp the animation index within how many the entity has
	if (currentAnimationIndex >= animationsCount):
		currentAnimationIndex = 0;
	elif (currentAnimationIndex < 0):
		currentAnimationIndex = animationsCount - 1;
	# Set the frame to 0
	animationFrameIndex = 0;
	animationPreviewNameToReplace = DirAccess.get_directories_at(FileSearch.find_directory_by_name(selectedEntityType))[currentAnimationIndex];
	# Load the current animation
	currentLoadedAnimation.clear();
	for image in get_animation_from_folder(animationPreviewNameToReplace):
		currentLoadedAnimation.append(ImageTexture.create_from_image(image));
	update_animation_preview();
	
## Change the animation frame currently shown
## next: Whether the user is changing to the next or previous frame
func frame_change(next : bool = true):
	# Change the animation frame index accordingly
	if (next):
		animationFrameIndex += 1;
	else:
		animationFrameIndex -= 1;
	var frameCount : int = currentLoadedAnimation.size();
	# Clamp the current index between 0 and the currently loaded animation amount
	if (animationFrameIndex >= frameCount):
		animationFrameIndex = 0;
	elif (animationFrameIndex < 0):
		animationFrameIndex = frameCount - 1;
	update_animation_preview();

## Update all parts of the animation preview
func update_animation_preview() -> void:
	animationName.text = animationPreviewNameToReplace;
	var frameCount = currentLoadedAnimation.size();
	frameCountLabel.text = str("Frame ", animationFrameIndex + 1, "/", frameCount)
	if (frameCount > 0):
		animationPreviewToReplace = currentLoadedAnimation[animationFrameIndex];
	else:
		animationPreviewToReplace = null;
	if (animationPreviewToReplace):
			animationPreviewTexture.texture = animationPreviewToReplace;

func play_preview_animation() -> void:
	playingAnimation = !playingAnimation;

func stop_preview_animation() -> void:
	playingAnimation = false;
	animationFrameIndex = 0;
	update_animation_preview();

func fps_updated(value: float) -> void:
	FPS = value;
