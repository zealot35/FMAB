extends MeshInstance3D

@export_group("Child Dependencies")
@export var liquidShaderMaterial: ShaderMaterial

@export_group("Liquid Simulation")
@export_range (0.0, 1.0, 0.001) var liquid_mobility: float = 0.1 

@export var springConstant : float = 200.0
@export var reaction       : float = 4.0
@export var dampening      : float = 3.0

@onready var pos1 : Vector3 = get_global_transform().origin
@onready var pos2 : Vector3 = pos1
@onready var pos3 : Vector3 = pos2

var vel    : float = 0.0
var accell : Vector2
var coeff : Vector2
var coeff_old : Vector2
var coeff_old_old : Vector2

func _ready():
	if liquidShaderMaterial == null:
		return
	liquidShaderMaterial = liquidShaderMaterial.duplicate_deep()
	set_surface_override_material(0, get_surface_override_material(0).duplicate())
	get_surface_override_material(0).next_pass = liquidShaderMaterial

func _physics_process(delta):
	var accell_3d:Vector3 = (pos3 - 2 * pos2 + pos1) * 3600.0
	pos1 = pos2
	pos2 = pos3
	pos3 = get_global_transform().origin + rotation
	accell = Vector2(accell_3d.x + accell_3d.y, accell_3d.z + accell_3d.y)
	coeff_old_old = coeff_old
	coeff_old = coeff
	coeff = (-springConstant * coeff_old - reaction * accell) / 3600.0 + 2 * coeff_old - coeff_old_old - delta * dampening * (coeff_old - coeff_old_old)
	liquidShaderMaterial.set_shader_parameter("coeff", coeff*liquid_mobility)
	if (pos1.distance_to(pos3) < 0.01):
		vel = clamp (vel-delta*1.0,0.0,1.0)
	else:
		vel = 1.0
	liquidShaderMaterial.set_shader_parameter("vel", vel)
