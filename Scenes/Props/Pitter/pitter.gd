extends PropBase

# enum INGREDIENT_TAGS {HEATED, CHILLED, SOLUTION, SPIRITS, POWDER, JUICE, MASHED, UNSEEDED, AGED, BLEND}

@export var unaccepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = [
	IngredientBase.INGREDIENT_TAGS.SOLUTION,
	IngredientBase.INGREDIENT_TAGS.SPIRITS,
	IngredientBase.INGREDIENT_TAGS.POWDER,
	IngredientBase.INGREDIENT_TAGS.JUICE,
	IngredientBase.INGREDIENT_TAGS.MASHED,
	IngredientBase.INGREDIENT_TAGS.UNSEEDED,
	IngredientBase.INGREDIENT_TAGS.AGED,
	IngredientBase.INGREDIENT_TAGS.BLEND,
]

@onready var lever : Node3D = $LeverNode
@onready var leverPhys : PropBase = $Lever
@onready var pitArm : MeshInstance3D = $PitArm
@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var output : Node3D = $Output
@onready var input_area : Area3D = $Input


var done_ready : bool = false
var processing_thing : bool = false

var processing_ingredient : IngredientBase

func _ready():
	super()
	input_area.body_entered.connect(input)
	done_ready = true

func input(body):
	# check for prop
	if !(body.get_parent() is PropBase):
		return
	
	# now check for ingredient
	var prop : PropBase = body.get_parent()

	if !(prop is IngredientBase):
		return
	
	var ing : IngredientBase = prop as IngredientBase

	var has_process : bool = false
	# check if ingredient is correct processing

	# exclusion check, only heated/chilled process is allowed
	for i in unaccepted_tags:
		if ing.ingredient_tags.has(i):
			has_process = true
			break

	# already been pitted by dude

	# not the right type of ingredient	
	if has_process:
		return
	
	# only fruits allowed
	if ing.ingredient_type != IngredientBase.REAGENT.FRUIT:
		return

	# accept it with open arms
	processing_ingredient = ing
	GLOBAL.player.physicsGrabbing(true)
	ing._mainPhysObject.global_position = output.global_position
	ing._mainPhysObject.linear_velocity = Vector3()
	await get_tree().create_timer(0.2).timeout
	ing.disablePhysics(true)
	particles.emitting = false
	processing_thing = true

func _physics_process(delta):
	if !done_ready:
		return
	lever.look_at(leverPhys.global_position)

	pitArm.position.z = lerpf(pitArm.position.z, -0.3 + (clamp(lever.rotation_degrees.x, 0.1, 30.0) / 120.0), delta*3)

	if processing_ingredient == null:
		return

	if processing_thing:
		if pitArm.position.z >= -0.06:
			processIngredient()

	pass

func processIngredient():
	processing_ingredient._mainPhysObject.global_position = output.global_position
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	particles.emitting = true
	processing_thing = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.UNSEEDED)
