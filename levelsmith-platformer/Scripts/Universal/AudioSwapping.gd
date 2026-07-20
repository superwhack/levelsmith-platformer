extends Node

# Reference to the asset manager
@export var assetManager : AssetManager;

var audioNameToReplace : String;

# All types of audio
var audioTypes : Array[String] = ["BounceTile", "CoinPickup", "EnemyDie", "Shoot", "Hurt", "PlayerDie", "Jump", "Victory", "WalkingGeneral", "WalkingIce", "WalkingSlime", "LevelMusic", "CheckpointReached"];

var loadedPreviewAudio : AudioStream;
var previewAudioPlayer : AudioStreamPlayer;

@export var playButton : Button;
@export var stopButton : Button;
var isPlayingPreview : bool = false;

@export var audioTimeline : HSlider;
@export var timeStampLabel : Label;

@export var volumeSlider : VBoxContainer;

var audioLength : float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previewAudioPlayer = AudioStreamPlayer.new();
	add_child(previewAudioPlayer);
	playButton.pressed.connect(play_preview_audio);
	stopButton.pressed.connect(preview_audio_finished);
	previewAudioPlayer.finished.connect(stop_preview)
	audioTimeline.drag_started.connect(drag_started);
	audioTimeline.drag_ended.connect(drag_ended);
	volumeSlider.drag_ended.connect(change_volume);

func _process(_delta: float) -> void:
	timeStampLabel.text = str(get_converted_time(audioTimeline.value), "/", get_converted_time(audioLength));
	#timeStampLabel.text = str("%.2f" % audioTimeline.value, "/", "%.2f" % audioLength);
	if (previewAudioPlayer.playing):
		audioTimeline.value = previewAudioPlayer.get_playback_position();
	
	# Hotkeys	
	if ( Input.is_action_just_pressed( "UI-AssetMgr-accept" ) ):
		play_preview_audio();
	if ( Input.is_action_just_pressed( "UI-AssetMgr-deny" ) ):
		preview_audio_finished();
	if ( Input.is_action_just_pressed( "right" ) ):
		audioTimeline.value += 0.02;
	if ( Input.is_action_just_pressed( "left" ) ):
		audioTimeline.value -= 0.02;

## Replaces the currently previewed audio  with one chosen via file dialog.
## newAudioPath: The file path of the new audio replacing the old one.x 
func replace_audio(newAudioPath: String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(audioNameToReplace);
	var targetDirectory : DirAccess = assetManager.clear_files(audioNameToReplace);
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

func save_mp3_stream(stream : AudioStreamMP3, filePath : String) -> void:
	var bytes : PackedByteArray = stream.data;
	
	if (bytes.is_empty()):
		print("AudioStreamMP3 has no data");
		return;
	
	var file = FileAccess.open(filePath, FileAccess.WRITE);
	
	if (file):
		file.store_buffer(bytes);
		file.close();

func save_ogg_stream(sourcePath : String, filePath : String) -> void:
	DirAccess.copy_absolute(sourcePath, filePath);

func change_volume() -> void:
	AudioManager.soundLevels[audioNameToReplace] = volumeSlider.value / 100.0;
	print(AudioManager.soundLevels)

func stop_preview():
	previewAudioPlayer.stop();
	isPlayingPreview = false;
	audioTimeline.value = 0;
	
func preview_audio_finished() -> void:
	if (loadedPreviewAudio):
		previewAudioPlayer.play();
		previewAudioPlayer.stream_paused = true;
		isPlayingPreview = false;
		audioTimeline.value = 0;

## Plays the preview audio. 
func play_preview_audio() -> void:
	#previewAudioPlayer.volume_db = linear_to_db(AudioManager.masterVolume * AudioManager.SFXVolume * volumeSlider.value / 100.0);
	if (!previewAudioPlayer.playing):
		previewAudioPlayer.play(audioTimeline.value)
	isPlayingPreview = !isPlayingPreview
	previewAudioPlayer.stream_paused = !isPlayingPreview;

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

func drag_started():
	previewAudioPlayer.stream_paused = true;

func drag_ended(value_changed : bool):
	if (value_changed):
		previewAudioPlayer.play(audioTimeline.value);
		previewAudioPlayer.stream_paused = !isPlayingPreview;

func get_converted_time(time : float) -> String:
	var minutes : int = floori(time / 60.0);
	time -= (minutes * 60.0);
	var seconds : int = floori(time);
	time -= seconds;
	var milliseconds = time*100;
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds];
