extends PropBase

# Potion crafting will be putting ingredients on the area, pulling a lever,
# and waiting for lightning to strike. The crafter will spawn a potion in
# place of the ingredients.

# generate the recipe for x potions
# store the potions away for spawning
# wait for the ingredients to match

@onready var initial_height : float = global_position.y
@onready var flash : OmniLight3D = $InputArea/OmniLight3D
@onready var lightning : MeshInstance3D = $InputArea/lightning1
@onready var particles : GPUParticles3D = $InputArea/GPUParticles3D
@onready var lightningSound : AudioStreamPlayer3D = $InputArea/LightningSound
@onready var inputArea : Area3D = $InputArea
@onready var output : Node3D = $Body/PotionOutput

var is_ready : bool = false
var descend : bool = false

var wait_amt : float = 0.0
var wait_time : float = 5.0

var matching_ingredients : Array = []


func _ready():
	super()
	GLOBAL.potionCrafter = self
	is_ready = true
	inputArea.body_entered.connect(ingredientEnter)


func _physics_process(delta):
	super(delta)

	if !is_ready:
		return
	if !GLOBAL.in_game:
		return
	
	if wait_amt >= wait_time:
		if !descend:
			_mainPhysObject.global_position.y += delta
		else:
			_mainPhysObject.global_position.y -= delta
		if _mainPhysObject.global_position.y > initial_height + 8.0:
			tryCraft()
			descend = true
			wait_amt = 0.0
		elif _mainPhysObject.global_position.y <= initial_height:
			descend = false
			matching_ingredients.clear()
			wait_amt = 0.0
	else:
		wait_amt += delta

	


func ingredientEnter(body):
	var _ing = body.get_parent()

	if !(_ing is IngredientBase):
		return
	matching_ingredients.append(_ing.ingredient_name)


func tryCraft():
	if !GLOBAL.in_game:
		return
	var _r : Array = GLOBAL.current_potion.recipe.duplicate()
	for i in matching_ingredients:
		if _r.has(i):
			_r.erase(i)
		# check each ingredient, if it matches, erase from _r
		pass
	
	if !_r.is_empty():
		return
		# we have all the ingredients, craft potion
	
	doEffect()
	matching_ingredients.clear()
	GLOBAL.clearIngredients()
	GLOBAL.spawnPotion()


func doEffect():
	particles.emitting = true
	lightningSound.play(0.9)
	lightning.visible = true
	flash.light_energy = 3.0
	await get_tree().create_timer(0.3).timeout
	flash.light_energy = 0.0
	lightning.visible = false
