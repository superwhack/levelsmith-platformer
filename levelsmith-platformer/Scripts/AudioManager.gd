extends Node

var masterVolume := 1.0;
var musicVolume := 1.0;
var SFXVolume := 1.0;

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

func music_loop(player: AudioStreamPlayer) -> void:
	player.play();
func audio_finished(player: AudioStreamPlayer) -> void:
	availablePlayers.append(player);
	inusePlayers.erase(player);

# NOTE: isUI might not be needed here since there's only two tracks, not sure yet though
## Play the music track
## musicName: name of the sound effect
## isUI: true if the music is tied to the UI, meaning the user doesn't adjust it
func play_music(musicName: String, isUI: bool = false) -> void:
	musicPlayer.stop();
	if isUI:
		musicPlayer.stream = load(UIAudioLibraryPath + musicName + ".mp3");
	else:
		musicPlayer.stream = load(audioLibraryPath + musicName + ".mp3");
	musicPlayer.play();

## Add specified SFX to the queue
## effectName: name of the sound effect
## isUI: true if the SFX is tied to the UI, meaning the user doesn't adjust it
func play_effect(effectName: String, isUI: bool = false) -> void:
	if isUI:
		queue.append(UIAudioLibraryPath + effectName + ".wav");
	else:
		queue.append(audioLibraryPath + effectName + ".wav");

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
