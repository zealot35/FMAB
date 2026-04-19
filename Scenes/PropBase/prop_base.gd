extends Node3D
class_name PropBase

enum PROP_SIZES {GRABBABLE, STATIC}

@onready var glass_sounds : Array = [
	load("res://Resources/Sounds/glass_01.ogg"),
	load("res://Resources/Sounds/glass_02.ogg"),
	load("res://Resources/Sounds/glass_03.ogg"),
	load("res://Resources/Sounds/glass_04.ogg"),
	load("res://Resources/Sounds/glass_05.ogg"),
	load("res://Resources/Sounds/sfx100v2_glass_01.ogg"),
	load("res://Resources/Sounds/sfx100v2_glass_02.ogg"),
	load("res://Resources/Sounds/sfx100v2_glass_03.ogg"),
	load("res://Resources/Sounds/sfx100v2_glass_04.ogg"),
	load("res://Resources/Sounds/sfx100v2_glass_05.ogg"),
	load("res://Resources/Sounds/sfx100v2_glass_06.ogg"),
]

@onready var normal_sounds : Array = [
	load("res://Resources/Sounds/wood_hit_06.ogg"),
	load("res://Resources/Sounds/wood_hit_07.ogg"),
	load("res://Resources/Sounds/wood_hit_08.ogg"),
	load("res://Resources/Sounds/wood_hit_09.ogg"),
	load("res://Resources/Sounds/wood_misc_03.ogg"),
	load("res://Resources/Sounds/wood_misc_06.ogg"),
	load("res://Resources/Sounds/wood_misc_07.ogg"),
	load("res://Resources/Sounds/wood_misc_08.ogg"),
]


@export_category("Object Info")
@export var prop_name : String = "Balls"
@export_multiline var prop_desc : String = "A ball."
@export_enum("GRABBABLE", "STATIC") var prop_size : int = PROP_SIZES.GRABBABLE
@export var selectable : bool = true
@export var is_glass : bool = false
@export var should_play_sounds : bool = false

@export_category("Technical Shit")
## Turning this on will make the global transform of the prop be the exact same as the first
## physics object it finds.
@export var prop_follows_phys_object : bool = true
@export var can_grab_prop : bool = true
@export_flags_3d_physics var prop_collision_layers : int = 1
@export_flags_3d_physics var prop_collision_mask : int = 1
@export var prop_hovertarget : NodePath

var _mainPhysObject : PhysicsBody3D
var _audioPlayer : AudioStreamPlayer3D

func _ready():
	_audioPlayer = AudioStreamPlayer3D.new()
	add_child(_audioPlayer)
	_audioPlayer.volume_db = -1.0
	_audioPlayer.unit_size = 0.4
	_audioPlayer.bus = "Physics"
	_audioPlayer.stream = AudioStreamPolyphonic.new()
	_audioPlayer.play()
	for i in get_children():
		if i is PhysicsBody3D:
			if GLOBAL.debug_mode:
				print("physics object found!  ", i.name)
			_mainPhysObject = i
			break
	
	if prop_follows_phys_object:
		if _mainPhysObject != null:
			_mainPhysObject.global_transform = global_transform
			_mainPhysObject.top_level = true
	
	if _mainPhysObject != null:
		if _mainPhysObject is RigidBody3D:
			_mainPhysObject.contact_monitor = true
			_mainPhysObject.max_contacts_reported = 1
			_mainPhysObject.body_entered.connect(bump)
		_mainPhysObject.collision_layer = prop_collision_layers
		_mainPhysObject.collision_mask = prop_collision_mask


func _physics_process(_delta):
	if (_mainPhysObject != null):
		if prop_follows_phys_object:
			global_transform = _mainPhysObject.global_transform


func disablePhysics(disable : bool):
	if (_mainPhysObject != null):
		process_mode = Node.PROCESS_MODE_DISABLED if disable else Node.PROCESS_MODE_INHERIT
		selectable = !disable


func interact() -> bool:
	return false


func isGrabbable() -> bool:
	return can_grab_prop


func hoverTarget() -> Vector3:
	if get_node_or_null(prop_hovertarget) == null:
		return global_position if !prop_follows_phys_object else _mainPhysObject.global_position
	else:
		return get_node_or_null(prop_hovertarget).global_position


func bump(body):
	#prop plays sound

	if !should_play_sounds:
		return
	var playback : AudioStreamPlaybackPolyphonic = _audioPlayer.get_stream_playback()

	if is_glass: # play a glass sound
		var r : int = randi() % glass_sounds.size()
		playback.play_stream(glass_sounds[r])
		pass
	else: # play a normal ass sound yo
		var r : int = randi() % normal_sounds.size()
		playback.play_stream(normal_sounds[r])
		pass
	pass
