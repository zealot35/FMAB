extends PropBase

@export var accepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = []
@export var max_process : float = 10.0

@onready var wheel : PropBase = $Wheel
@onready var inputArea : Area3D = $Input
@onready var output : Node3D = $Output
@onready var hotParticles : GPUParticles3D = $HotParticles
@onready var coldParticles : GPUParticles3D = $ColdParticles
@onready var fireEffect : MeshInstance3D = $Fire
@onready var particleCol : GPUParticlesCollisionHeightField3D = $GPUParticlesCollisionHeightField3D

var rotate_time : float = 0.0

var done_ready : bool = false
var process_amount : float = 0.0
var process_max : float = 10.0
var temp_control : float = 0.0
var is_doing_temp : bool = false
var processing_thing : bool = false

var processing_ingredient : IngredientBase


func _ready():
	super()
	particleCol.force_update_transform()
	inputArea.body_entered.connect(input)
	done_ready = true

func _physics_process(delta):
	super(delta)

	# print(wheel.global_basis.x)

	if wheel._mainPhysObject.angular_velocity.x > 1.0:
		temp_control += delta
	elif wheel._mainPhysObject.angular_velocity.x < -1.0:
		temp_control -= delta
	else:
		temp_control = lerpf(temp_control, 0.0, delta*4)
	
	temp_control = clampf(temp_control, -3.0, 3.0)
	is_doing_temp = false
	if temp_control > 1.0:
		# hot
		is_doing_temp = true
		coldParticles.emitting = false
		hotParticles.emitting = true
		fireEffect.visible = true
	elif temp_control < -1.0:
		is_doing_temp = true
		#cold
		coldParticles.emitting = true
		hotParticles.emitting = false
		fireEffect.visible = false
	else:
		#stale
		coldParticles.emitting = false
		hotParticles.emitting = false
		fireEffect.visible = false
	
	if is_doing_temp:
		if processing_thing:
			process_amount += delta

			if process_amount >= process_max:
				processIngredient()
			# we are doing itittt


func input(body):
	# check for prop
	if !(body.get_parent() is PropBase):
		return
	
	# now check for ingredient
	var prop : PropBase = body.get_parent()

	if !(prop is IngredientBase):
		return
	
	var ing : IngredientBase = prop as IngredientBase

	# var has_process : bool = false
	# # check if ingredient is correct processing
	# for i in accepted_tags:
	# 	if ing.ingredient_tags.has(i):
	# 		has_process = true
	# 		break

	# # not the right type of ingredient	
	# if !has_process:
	# 	return

	# accept it with open arms
	processing_ingredient = ing
	GLOBAL.player.physicsGrabbing(true)
	ing.visible = false
	ing.disablePhysics(true)
	processing_thing = true
	process_amount = 0.0


func processIngredient():
	processing_ingredient._mainPhysObject.global_position = output.global_position
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	hotParticles.emitting = false
	coldParticles.emitting = false
	processing_thing = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	if temp_control > 1.0:
		processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.HEATED)
	else:
		processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.CHILLED)
