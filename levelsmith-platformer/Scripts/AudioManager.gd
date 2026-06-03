extends Node

var masterVolume := 1.0;
var musicVolume := 1.0;
var SFXVolume := 1.0;
# Lowest DB, should be inaudible (it's negative)
const lowestDB = 80;

const audioPlayerCount := 6;
# NOTE: This would be a folder alongside the other assets in the user's local directory, it needs to be changed
const audioLibraryPath := "res://Assets/Audio/";
const UIAudioLibraryPath := "res://Assets/Audio/";

var musicPlayer : AudioStreamPlayer;
var availablePlayers : Array[AudioStreamPlayer];
var inusePlayers : Array[AudioStreamPlayer]
var queue : Array[String];

func _ready() -> void:
	musicPlayer = AudioStreamPlayer.new();
	add_child(musicPlayer);
	musicPlayer.finished.connect(music_loop.bind(musicPlayer));
	musicPlayer.bus = "master";
	
	# Loop through and create every potential audioPlayer for use with UI and in game
	for i in audioPlayerCount:
		var audioPlayer = AudioStreamPlayer.new();
		add_child(audioPlayer);
		availablePlayers.append(audioPlayer);
		audioPlayer.finished.connect(audio_finished.bind(audioPlayer));
		audioPlayer.bus = "master";

## Only done with music, loop instead of ending it
## player: the audio stream player running the music
func music_loop(player: AudioStreamPlayer) -> void:
	player.play();

## Once the audio track is finished
## player: the audio stream player to end
func audio_finished(player: AudioStreamPlayer) -> void:
	availablePlayers.append(player);
	inusePlayers.erase(player);

func update_volume() -> void:
	musicPlayer.volume_db = (lowestDB * masterVolume * musicVolume) - lowestDB;
	print(musicPlayer.volume_db);
	for i in inusePlayers.size():
		inusePlayers[i].volume_db = (lowestDB * masterVolume * SFXVolume) - lowestDB;
	for i in availablePlayers.size():
		availablePlayers[i].volume_db = (lowestDB * masterVolume * SFXVolume) - lowestDB;

# NOTE: isUI might not be needed here since there's only two tracks, not sure yet though
## Play the music track
## musicName: name of the sound effect
## isUI: true if the music is tied to the UI, meaning the user doesn't adjust it
func play_music(musicName: String, isUI: bool = false) -> void:
	musicPlayer.stop();
	var fullPath : String;
	if isUI:
		fullPath = UIAudioLibraryPath;
	else:
		fullPath = audioLibraryPath;
	fullPath += musicName;
	if FileAccess.file_exists(fullPath + ".mp3"):
		musicPlayer.stream = load(fullPath + ".mp3");
	elif FileAccess.file_exists(fullPath + ".wav"):
		musicPlayer.stream = load(fullPath + ".wav");
	else:
		print("File not found or doesn't use .wav/.mp3!");
		return;
	musicPlayer.play();

## Add specified SFX to the queue
## effectName: name of the sound effect
## isUI: true if the SFX is tied to the UI, meaning the user doesn't adjust it
func play_effect(effectName: String, isUI: bool = false) -> void:
	var fullPath : String;
	if isUI:
		fullPath = UIAudioLibraryPath;
	else:
		fullPath = audioLibraryPath;
	fullPath += effectName;
	if FileAccess.file_exists(fullPath + ".mp3"):
		queue.append(fullPath + ".mp3");
	elif FileAccess.file_exists(fullPath + ".wav"):
		queue.append(fullPath + ".wav");
	else:
		print("File not found or doesn't use .wav/.mp3!");
		return;

## Reset and stop all audio
func reset_audio() -> void:
	for i in inusePlayers.size():
		inusePlayers[i].stop();
		availablePlayers.append(inusePlayers[i]);
	inusePlayers.clear();
	musicPlayer.stop();

## If there are any current sounds in the queue and any avaliable players, start playing the sound.
## delta: unused
func _process(delta: float) -> void:
	if !queue.is_empty() && !availablePlayers.is_empty():
		availablePlayers[0].stream = load(queue.pop_front());
		availablePlayers[0].play();
		availablePlayers.pop_front();
