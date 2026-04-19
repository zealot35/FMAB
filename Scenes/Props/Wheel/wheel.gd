extends PropBase

signal just_clicked()

@onready var wheelMesh : MeshInstance3D = $RigidBody3D/MeshInstance3D
@onready var wheelClick := preload("res://Resources/Sounds/wood_hit_06.ogg")
@onready var soundPlayer : AudioStreamPlayer3D = $RigidBody3D/AudioStreamPlayer3D

var is_ready : bool = false
var prev_x : float = 0.0

func _ready():
	super()
	is_ready = true
	soundPlayer.stream = AudioStreamPolyphonic.new()
	soundPlayer.stream.polyphony = 128
	soundPlayer.play()

func _physics_process(delta):
	super(delta)
	if !is_ready:
		return
	
	if _mainPhysObject.angular_velocity.length() > 0.5:
		print(_mainPhysObject.angular_velocity)

	if snappedf(prev_x, 0.3) != snappedf(wheelMesh.global_basis.z.z + wheelMesh.global_basis.z.y, 0.3):
		playSound()
	prev_x = wheelMesh.global_basis.z.z + wheelMesh.global_basis.z.y


func interact():
	if _mainPhysObject.angular_velocity.x > 1.0:
		_mainPhysObject.angular_velocity.x = -9.0
	else:
		_mainPhysObject.angular_velocity.x = 9.0

	pass


func playSound():
	var playback : AudioStreamPlaybackPolyphonic = soundPlayer.get_stream_playback()

	playback.play_stream(wheelClick)

	just_clicked.emit()
