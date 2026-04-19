extends PropBase

@export var accepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = [
	IngredientBase.INGREDIENT_TAGS.SPIRITS,
	IngredientBase.INGREDIENT_TAGS.POWDER,
]


@onready var liquid : MeshInstance3D = $StaticBody3D/Bucket/Liquid
@onready var pourNode : Node3D = $StaticBody3D/Pourer/PouringNode
@onready var particles : GPUParticles3D = $StaticBody3D/Pourer/PouringNode/NiagaraBottle/GPUParticles3D
@onready var bottleProp : PropBase = $StaticBody3D/Pourer/Bottle
@onready var inputArea : Area3D = $Input
@onready var output : Node3D = $Output
@onready var waterStream : AudioStreamPlayer3D = $StaticBody3D/Bucket/WaterStream


var done_ready : bool = false
var fill_amount : float = 0.0
var processing_thing : bool = false

var processing_ingredient : IngredientBase

func _ready():
	super()
	done_ready = true
	inputArea.body_entered.connect(inputEntered)
	pass

func _physics_process(delta):
	super(delta)
	if !done_ready:
		return
	particles.emitting = pourNode.rotation_degrees.x > 0.0

	if !waterStream.playing:
		waterStream.playing = particles.emitting
	elif !particles.emitting && waterStream.playing:
		waterStream.stop()

	pourNode.look_at(bottleProp.global_position)

	if pourNode.rotation_degrees.x > 20.0 && pourNode.rotation_degrees.x < 70.0:
		fill_amount += delta * 0.1
	else:
		fill_amount -= delta * 0.5
	fill_amount = clampf(fill_amount, 0.0, 1.0)
	
	if fill_amount >= 1.0 && processing_thing:
		processIngredient()

	if fill_amount == 0.0:
		liquid.visible = false
	else:
		liquid.visible = true
		liquid.mesh.top_radius = 0.4 + (fill_amount * 0.05)
		liquid.position.y = 0.1 + (fill_amount * 0.25)
		liquid.mesh.height = 0.1 + (fill_amount * 0.5)


func processIngredient():
	processing_ingredient._mainPhysObject.global_position = output.global_position
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	particles.emitting = false
	processing_thing = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.SOLUTION)


func inputEntered(body):
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

	# if the ingredient is a fruit, it must be unseeded or mashed
	# if the ingredient is a wet, it just has to be whole or mashed
	# wets cannot be unseeded...... obviously

	# accept it with open arms
	processing_ingredient = ing
	GLOBAL.player.physicsGrabbing(true)
	ing.visible = false
	ing.disablePhysics(true)
	processing_thing = true
	fill_amount = 0.0
