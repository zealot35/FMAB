extends HingeJoint3D

var readied : bool = false

@onready var pos1 : Vector3 = get_node_or_null(node_b).get_global_transform().origin
@onready var pos2 : Vector3 = pos1
@onready var pos3 : Vector3 = pos2

var vel : float = 0.0
var accell : Vector2

func _ready():
	readied = true

func _physics_process(delta):
	if !readied:
		return

	var accell_3d:Vector3 = (pos3 - 2 * pos2 + pos1) * 100.0
	pos1 = pos2
	pos2 = pos3
	pos3 = get_node_or_null(node_b).get_global_transform().origin + get_node_or_null(node_b).global_rotation
	# accell = Vector2(accell_3d.x + accell_3d.y, accell_3d.z + accell_3d.y)
	$Label3D.text = "Spinning: "
	$Label3D.text += "UP\n" if get_node_or_null(node_b).angular_velocity.z < 0.0 else "DOWN\n"
	$Label3D.text += str(get_node_or_null(node_b).angular_velocity.z)
	# $Label3D.text = str(snapped(accell_3d, Vector3(0.01, 0.01, 0.01)))
	# print(get_node_or_null(node_b).angular_velocity)
