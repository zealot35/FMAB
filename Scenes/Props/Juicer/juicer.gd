extends PropBase

@export var accepted_tags : Array[IngredientBase.INGREDIENT_TAGS] = [
	IngredientBase.INGREDIENT_TAGS.UNSEEDED,
]
@export var max_juice : float = 15.0

@onready var wheel : PropBase = $Wheel
@onready var inputArea : Area3D = $Input
@onready var juiceOutput : Node3D = $OutputJuice
@onready var mashOutput : Node3D = $OutputMash
@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var waterStream : AudioStreamPlayer3D = $WaterStream

var is_ready : bool = false
var juice_amount : float = 0.0
var processing_thing : bool = false
var rotate_time : float = 0.0

var processing_ingredient : IngredientBase

func _ready():
	super()
	inputArea.body_entered.connect(input)
	wheel.just_clicked.connect(wheelClicked)
	is_ready = true


func _physics_process(delta):
	super(delta)

	if rotate_time > 0.0:
		rotate_time -= delta
		if !processing_thing:
			return
		# do juicing
		particles.emitting = true
		if !waterStream.playing:
			waterStream.playing = true
		juice_amount += delta

		if juice_amount >= max_juice:
			processIngredient()
			pass
	else:
		waterStream.stop()
		particles.emitting = false
	pass


func processIngredient():
	processing_ingredient._mainPhysObject.global_position = mashOutput.global_position
	processing_ingredient._mainPhysObject.linear_velocity = Vector3()
	processing_thing = false
	juice_amount = 0.0
	particles.emitting = false
	processing_ingredient.disablePhysics(false)
	processing_ingredient.visible = true
	processing_ingredient.addProcess(IngredientBase.INGREDIENT_TAGS.MASHED)

	var juice_ingredient : IngredientBase = GLOBAL.ingredient_scene.instantiate()
	var _dangers : Array = processing_ingredient.danger
	var _processes : Array = []
	var ing_id : int = processing_ingredient.ingredient_id
	var ing_type : int = processing_ingredient.ingredient_type
	if processing_ingredient.ingredient_tags.has(IngredientBase.INGREDIENT_TAGS.HEATED):
		_processes.append(IngredientBase.INGREDIENT_TAGS.HEATED)
	elif processing_ingredient.ingredient_tags.has(IngredientBase.INGREDIENT_TAGS.CHILLED):
		_processes.append(IngredientBase.INGREDIENT_TAGS.CHILLED)
	_processes.append(IngredientBase.INGREDIENT_TAGS.JUICE)
	juice_ingredient.setCustomIngredientStuff(ing_id, ing_type, _dangers, _processes)

	GLOBAL.ingredientHolder.add_child(juice_ingredient)
	juice_ingredient._mainPhysObject.global_position = juiceOutput.global_position





func input(body):
	# check for prop
	if !(body.get_parent() is PropBase):
		return
	
	# now check for ingredient
	var prop : PropBase = body.get_parent()

	if !(prop is IngredientBase):
		return
	
	print("hi")
	
	var ing : IngredientBase = prop as IngredientBase

	var has_process : bool = false
	# check if ingredient is correct processing
	for i in accepted_tags:
		if ing.ingredient_tags.has(i):
			has_process = true
			break
	
	if ing.ingredient_type == IngredientBase.REAGENT.WET:
		has_process = true
		for i in ing.ingredient_tags:
			if IngredientBase.temperature_tags.has(i):
				# good
				continue
			else:
				has_process = false
				break
	print(has_process)
			

	# not the right type of ingredient	
	if !has_process:
		return

	# accept it with open arms
	processing_ingredient = ing
	GLOBAL.player.physicsGrabbing(true)
	ing.visible = false
	ing.disablePhysics(true)
	processing_thing = true
	juice_amount = 0.0
	particles.emitting = true
	pass

func wheelClicked():
	print("Wheel just clicked innit")
	rotate_time = rotate_time + 0.25
	rotate_time = clampf(rotate_time, 0.0, 1.0)
