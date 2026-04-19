extends PropBase

@export var accepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = [
	IngredientBase.INGREDIENT_TAGS.MASHED,
]
@export var max_aging : float = 5.0


@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var output : Node3D = $Output
@onready var input_area : Area3D = $Input


var done_ready : bool = false
var age_amount : float = 0.0
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
	for i in accepted_tags:
		if ing.ingredient_tags.has(i):
			has_process = true
			break

	# not the right type of ingredient	
	if !has_process:
		return

	# accept it with open arms
	processing_ingredient = ing
	GLOBAL.player.physicsGrabbing(true)
	ing.visible = false
	ing.disablePhysics(true)
	processing_thing = true
	age_amount = 0.0
	particles.emitting = true
	pass

func _physics_process(delta):
	super(delta)
	if processing_ingredient == null:
		return
	
	if processing_thing:
		age_amount += delta

		if age_amount >= max_aging:
			processIngredient()

	pass

func processIngredient():
	processing_ingredient._mainPhysObject.global_position = output.global_position
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	particles.emitting = false
	age_amount = 0.0
	processing_thing = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.AGED)
