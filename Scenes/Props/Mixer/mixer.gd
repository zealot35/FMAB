extends PropBase

# enum INGREDIENT_TAGS {HEATED, CHILLED, SOLUTION, SPIRITS, POWDER, JUICE, MASHED, UNSEEDED, AGED, BLEND}

@export var accepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = [
	IngredientBase.INGREDIENT_TAGS.MASHED,
	IngredientBase.INGREDIENT_TAGS.UNSEEDED,
]
@export var max_process : float = 10.0


@onready var lever : Node3D = $LeverNode
@onready var leverPhys : PropBase = $Lever
@onready var wheel : PropBase = $Wheel
@onready var mixerBlade : MeshInstance3D = $Mixer/MixerBlade
@onready var particles : GPUParticles3D = $Mixer/GPUParticles3D
@onready var inputArea : Area3D = $Input
@onready var output : Node3D = $Output

var rotate_time : float = 0.0

var done_ready : bool = false
var process_amount : float = 0.0
var processing_thing : bool = false

var processing_ingredient : IngredientBase


func _ready():
	super()
	wheel.just_clicked.connect(wheelClicked)
	inputArea.body_entered.connect(inputEntered)
	done_ready = true

func _physics_process(delta):
	super(delta)

	lever.look_at(leverPhys.global_position)

	mixerBlade.position.y = lerpf(mixerBlade.position.y, 0.9 - (clamp(lever.rotation_degrees.x, 0.1, 30.0) / 120.0), delta*3)

	if rotate_time > 0.0:
		mixerBlade.rotate_y(delta * 16)
		rotate_time -= delta
	
		if mixerBlade.position.y < 0.7:
			particles.emitting = true
			doProcessing(delta)
			# do thing
			pass
		else:
			particles.emitting = false


func doProcessing(delta : float):
	if !processing_thing:
		return
	
	process_amount += delta

	if process_amount >= max_process:
		processIngredient()
		pass

	pass


func processIngredient():
	particles.emitting = false
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	processing_ingredient._mainPhysObject.global_position = output.global_position
	processing_thing = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	if processing_ingredient.ingredient_type == IngredientBase.REAGENT.DRY:
		processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.POWDER)
	else:
		processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.BLEND)



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

	if (ing.ingredient_type == IngredientBase.REAGENT.DRY):
			if ing.ingredient_tags.is_empty():
				has_process = true
			elif ing.ingredient_tags.size() <= 1:
				if (ing.ingredient_tags.has(IngredientBase.INGREDIENT_TAGS.HEATED) ||
					ing.ingredient_tags.has(IngredientBase.INGREDIENT_TAGS.CHILLED)):
					has_process = true
	elif (ing.ingredient_type == IngredientBase.REAGENT.FRUIT): # not dry, check for other tags
		for i in accepted_tags:
			if ing.ingredient_tags.has(i):
				has_process = true
				break
	else: # ingredient is wet
		has_process = true
		for i in ing.ingredient_tags:
			if !IngredientBase.temperature_tags.has(i):
				# fuck you
				has_process = false
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
	process_amount = 0.0


func wheelClicked():
	print("Wheel just clicked innit")
	rotate_time = rotate_time + 0.25
	rotate_time = clampf(rotate_time, 0.0, 3.0)
	
