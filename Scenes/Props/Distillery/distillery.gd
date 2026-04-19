extends PropBase


@export var accepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = [
	IngredientBase.INGREDIENT_TAGS.BLEND,
	IngredientBase.INGREDIENT_TAGS.JUICE,
	IngredientBase.INGREDIENT_TAGS.SOLUTION,
]


@onready var liquid : MeshInstance3D = $Bucket/Liquid
@onready var particles : GPUParticles3D = $StaticBody3D/Distillery/GPUParticles3D
@onready var output : Node3D = $Bucket/Output
@onready var input_area : Area3D = $Input


var done_ready : bool = false
var fill_amount : float = 0.0
var processing_thing : bool = false

var processing_ingredient : IngredientBase

func _ready():
	super()
	input_area.body_entered.connect(input)
	done_ready = true
	particles.emitting = false

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
	fill_amount = 0.0
	particles.emitting = true
	pass

func _physics_process(delta):
	super(delta)
	if processing_ingredient == null:
		return
	
	if processing_thing:
		fill_amount += delta * 0.1

		if fill_amount >= 1:
			processIngredient()
	else:
		fill_amount -= delta
	
	fill_amount = clampf(fill_amount, 0.0, 1.0)
	
	if fill_amount == 0.0:
		liquid.visible = false
	else:
		liquid.visible = true
		liquid.mesh.top_radius = 0.4 + (fill_amount * 0.05)
		liquid.position.y = 0.1 + (fill_amount * 0.25)
		liquid.mesh.height = 0.1 + (fill_amount * 0.5)

	pass

func processIngredient():
	processing_ingredient._mainPhysObject.global_position = output.global_position
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	particles.emitting = false
	processing_thing = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.SPIRITS)

