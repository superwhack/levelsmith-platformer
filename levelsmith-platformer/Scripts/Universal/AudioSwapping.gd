extends Node

# Reference to the asset manager
@export var assetManager : AssetManager;

# Name of the audio asset being replaced
var audioNameToReplace : String;

# All types of audio
var audioTypes : Array[String] = ["BounceTile", "CoinPickup", "EnemyDie", "Shoot", "Hurt", "PlayerDie", "Jump", "Victory", "WalkingGeneral", "WalkingIce", "WalkingSlime", "LevelMusic", "CheckpointReached"];

# Preview audio 
var loadedPreviewAudio : AudioStream;
var previewAudioPlayer : AudioStreamPlayer;
var isPlayingPreview : bool = false;
var audioScrubStep : float = 2;

# Button references
@export var playButton : Button;
@export var pauseButton : Button;
@export var stopButton : Button;

# Other references
@export var audioTimeline : HSlider;
@export var timeStampLabel : Label;

# Audio length in seconds.
var audioLength : float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previewAudioPlayer = AudioStreamPlayer.new();
	add_child(previewAudioPlayer);
	playButton.pressed.connect(play_preview_audio);
	pauseButton.pressed.connect(play_preview_audio.bind(false));
	stopButton.pressed.connect(preview_audio_finished);
	previewAudioPlayer.finished.connect(preview_audio_finished);
	audioTimeline.drag_started.connect(drag_started);
	audioTimeline.drag_ended.connect(drag_ended);

## Runs every frame. Handles visual feedback and hotkeys.
func _process(_delta : float) -> void:
	timeStampLabel.text = str(get_converted_time(audioTimeline.value), "/", get_converted_time(audioLength));
	if (previewAudioPlayer.playing):
		audioTimeline.value = previewAudioPlayer.get_playback_position();
	
	# Hotkeys	
	if ( Input.is_action_pressed( "shift" ) ): 
		audioScrubStep = 8;
	else :
		audioScrubStep = 2;
	
	if ( Input.is_action_just_pressed( "UI-AssetMgr-accept" ) ):
		play_preview_audio(!previewAudioPlayer.playing);
	if ( Input.is_action_just_pressed( "UI-AssetMgr-deny" ) ):
		preview_audio_finished();
	if ( Input.is_action_pressed( "right" ) ):
		if ( previewAudioPlayer.playing ) :
			play_preview_audio( false );
		audioTimeline.value += audioScrubStep * _delta ;
	if ( Input.is_action_pressed( "left" ) ):
		if ( previewAudioPlayer.playing ) :
			play_preview_audio( false );
		audioTimeline.value -= audioScrubStep * _delta ;

## Replaces the currently previewed audio  with one chosen via file dialog.
## newAudioPath: The file path of the new audio replacing the old one.x 
func replace_audio(newAudioPath: String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(audioNameToReplace);
	assetManager.clear_files(audioNameToReplace);
	
	print(newAudioPath);
	print(targetFilePath);
	# If the audio is mp3 or wav, create a copy
	if (newAudioPath.get_extension().to_lower() == "mp3"):
		var audio = AudioStreamMP3.new();
		audio = AudioStreamMP3.load_from_file(newAudioPath);
		if (!audio):
			PopUpManager.create_error_popup("Failure to load file", "The file at " + newAudioPath + " could not be loaded.");
			return;
		save_mp3_stream(audio, targetFilePath + "/" + audioNameToReplace + ".mp3");
	elif (newAudioPath.get_extension().to_lower() == "wav"):
		print("Wav file");
		var audio = AudioStreamWAV.new();
		audio = AudioStreamWAV.load_from_file(newAudioPath);
		print(audio);
		if (!audio):
			PopUpManager.create_error_popup("Failure to load file", "The file at " + newAudioPath + " could not be loaded.");
			return;
		audio.save_to_wav(targetFilePath + "/" + audioNameToReplace + ".wav")
	elif (newAudioPath.get_extension().to_lower() == "ogg"):
		var audio = AudioStreamOggVorbis.new();
		audio = AudioStreamOggVorbis.load_from_file(newAudioPath)
		if (!audio):
			PopUpManager.create_error_popup("Failure to load file", "The file at " + newAudioPath + " could not be loaded.");
			return;
		save_ogg_stream(newAudioPath, targetFilePath + "/" + audioNameToReplace + ".ogg");
	else:
		PopUpManager.create_error_popup("File type incorrect", "File must be .mp3 or .wav format.");
	load_preview_audio();

## Clears the audio in a given folder and replaces it with a default
func reset_audio() -> void:
	AudioManager.play_UI_effect("UISelection");
	assetManager.clear_files(audioNameToReplace);
	load_preview_audio();

## Saves the audio stream as an MP3 file.
## stream: The audio MP3 to save
## filePath: The name of the file being saved.
func save_mp3_stream(stream : AudioStreamMP3, filePath : String) -> void:
	var bytes : PackedByteArray = stream.data;
	
	if (bytes.is_empty()):
		print("AudioStreamMP3 has no data");
		return;
	
	var file = FileAccess.open(filePath, FileAccess.WRITE);
	
	if (file):
		file.store_buffer(bytes);
		file.close();

## Saves the audio stream as an OGG file.
## sourcePath: The audio file's original location
## filePath: The destination of the ogg file
func save_ogg_stream(sourcePath : String, filePath : String) -> void:
	DirAccess.copy_absolute(sourcePath, filePath);

## Resets the audio preview 
func stop_preview():
	previewAudioPlayer.stop();
	isPlayingPreview = false;
	audioTimeline.value = 0;

## When the audio privew is finished, replay it.
func preview_audio_finished() -> void:
	if (loadedPreviewAudio):
		play_preview_audio(false);
		previewAudioPlayer.play();
		previewAudioPlayer.stream_paused = true;
		isPlayingPreview = false;
		audioTimeline.value = 0;

## Plays the preview audio. 
func play_preview_audio(play : bool = true) -> void:
	if (play):
		previewAudioPlayer.play(audioTimeline.value);
	isPlayingPreview = play
	previewAudioPlayer.stream_paused = !isPlayingPreview;
	if (isPlayingPreview):
		pauseButton.show();
		playButton.hide();
	else:
		pauseButton.hide();
		playButton.show();

## Load all audio in the library to play in the preview. 
func load_preview_audio() -> void:
	loadedPreviewAudio = null;
	var audioPath = AudioManager.audioLibraryPath + audioNameToReplace + "/" + audioNameToReplace;
	if (FileAccess.file_exists(audioPath + ".mp3")):
		loadedPreviewAudio = AudioStreamMP3.new();
		loadedPreviewAudio = AudioStreamMP3.load_from_file(audioPath + ".mp3");
	elif (FileAccess.file_exists(audioPath + ".wav")):
		loadedPreviewAudio = AudioStreamWAV.new();
		loadedPreviewAudio = AudioStreamWAV.load_from_file(audioPath + ".wav");
	elif (FileAccess.file_exists(audioPath + ".ogg")):
		loadedPreviewAudio = AudioStreamOggVorbis.new();
		loadedPreviewAudio = AudioStreamOggVorbis.load_from_file(audioPath + ".ogg");
	if (loadedPreviewAudio == null):
		loadedPreviewAudio = AudioStreamWAV.new()
		loadedPreviewAudio = load(AudioManager.BACKUP_AUDIO_LIBRARY_PATH + audioNameToReplace + "/" + audioNameToReplace + ".wav");
	elif (loadedPreviewAudio.get_length() <= 0):
		PopUpManager.create_error_popup("Audio length is 0", "Currently loaded audio for " + audioNameToReplace + " has a length of zero. Using default instead.")
		loadedPreviewAudio = AudioStreamWAV.new()
		loadedPreviewAudio = load(AudioManager.BACKUP_AUDIO_LIBRARY_PATH + audioNameToReplace + "/" + audioNameToReplace + ".wav");
	previewAudioPlayer.stream = loadedPreviewAudio;
	preview_audio_finished();
	audioLength = loadedPreviewAudio.get_length()
	audioTimeline.max_value = audioLength;

## Occurs when dragging the audio timeline slider.
func drag_started():
	previewAudioPlayer.stream_paused = true;

## Play the audio at the "time" value of the slider after being dragged.
## valueChanged: Whether the time was changed since before the slider was dragged.
func drag_ended(valueChanged : bool):
	if (valueChanged):
		previewAudioPlayer.play(audioTimeline.value);
		previewAudioPlayer.stream_paused = !isPlayingPreview;

## Convert a float value in seconds to minutes/seconds/milliseconds format.
func get_converted_time(time : float) -> String:
	var minutes : int = floori(time / 60.0);
	time -= (minutes * 60.0);
	var seconds : int = floori(time);
	time -= seconds;
	var milliseconds = time*100;
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds];
