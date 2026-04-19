extends Node3D

@onready var stormSound : AudioStreamPlayer3D = $StormSound
@onready var towerPos : Node3D = $TowerPosition
@onready var menuPos : Node3D = $MenuPosition
@onready var rotator : Node3D = $Rotator
@onready var animPlayer : AnimationPlayer = $AnimationPlayer
@onready var flash : OmniLight3D = $Rotator/flash

var thunder_loop := preload("res://Resources/Sounds/rain-thunder.wav")
var rain_loop := preload("res://Resources/Sounds/rain-loop.wav")

var rains : Array = []
enum STORM {RAIN, LIGHTNING}

func _ready():
	stormSound.stream = AudioStreamPolyphonic.new()
	animPlayer.animation_finished.connect(lightningEnd)
	stormSound.play()
	var playback = stormSound.get_stream_playback()
	playLightning()
	## puts the playback stream id and 1 which represents lightning loop
	rains.append([playback.play_stream(thunder_loop), STORM.LIGHTNING])


func _physics_process(delta):
	var check_lightning : bool = false
	for i in rains:
		check_lightning = false
		if i[1] == STORM.LIGHTNING:
			check_lightning = true
			# we check this one for the sweet lightning
		if stormSound.get_stream_playback().is_stream_playing(i[0]):
			continue
		stormSoundFinish()
		
	if GLOBAL.in_game:
		stormSound.global_position = towerPos.global_position
		stormSound.unit_size = 11.0
	else:
		stormSound.unit_size = 6.0
		stormSound.global_position = menuPos.global_position


func stormSoundFinish():
	rains.clear()
	var r : int = randi() % 10
	print(r)
	var playback = stormSound.get_stream_playback()
	if r > 6:
		rains.append([playback.play_stream(thunder_loop), STORM.LIGHTNING])
		playLightning()
	else:
		rains.append([playback.play_stream(rain_loop), STORM.RAIN])


func playLightning():
	var r : int = randi() % 2
	rotator.rotation_degrees.y = randi() % 360
	await get_tree().create_timer(19.0).timeout
	flash.omni_range = 600.0
	if r == 0:
		animPlayer.play("lightning")
	else:
		animPlayer.play("lightning2")


func lightningEnd(anim_name : String):
	if anim_name == "RESET":
		return
	animPlayer.play("RESET")
	flash.omni_range = 1.0
