@tool
extends PropBase
class_name IngredientBase

enum INGREDIENT_TAGS {HEATED, CHILLED, SOLUTION, SPIRITS, POWDER, JUICE, MASHED, UNSEEDED, AGED, BLEND}

enum REAGENT {FRUIT, WET, DRY}

# potent ingredients explode if colliding past a certain velocity. constantly gives off a slight glow
# energetic ingredients tend to move against your will. constantly vibrates
# gaseous ingredients tend to float sometimes, falling back down. don't drop when see-through
# anti ingredients will vaporize you upon touch every once in a while. drop it when it glows
# phase ingredients tend to teleport you. drop it when it glows
# emergent ingredients tend to exhibit random properties.

# ingredients will be inhibited by the potion crafter

enum DANGER_TAGS {POTENT, ENERGETIC, GASEOUS, ANTI, PHASE, EMERGENT}
enum COLL_TAGS {SMALL, MED, LARGE, HORN}

@onready var generalHatchMaterial := preload("res://Resources/Shaders/GeneralHatchToon.tres")
@onready var waterHatchMaterial := preload("res://Resources/Shaders/NotMovingWaterToon.tres")

@onready var coll : Dictionary = {
	COLL_TAGS.SMALL: $RigidBody3D/Small,
	COLL_TAGS.MED: $RigidBody3D/Medium,
	COLL_TAGS.LARGE: $RigidBody3D/Large,
	COLL_TAGS.HORN: $RigidBody3D/Horn,
}

@onready var dangerMaterials : Dictionary = {
	DANGER_TAGS.ENERGETIC: null,
	DANGER_TAGS.EMERGENT: null,
	DANGER_TAGS.POTENT: preload("res://Resources/Shaders/Potent.tres"),
	DANGER_TAGS.GASEOUS: preload("res://Resources/Shaders/Gaseous.tres"),
	DANGER_TAGS.ANTI: preload("res://Resources/Shaders/Anti.tres"),
	DANGER_TAGS.PHASE: preload("res://Resources/Shaders/Phase.tres"),
}

@onready var meshes : Dictionary = {
	"Apple": [$Meshes/Apple, COLL_TAGS.SMALL, Color.ORANGE_RED],
	"Orange": [$Meshes/Orange, COLL_TAGS.SMALL, Color.ORANGE],
	"Papaya": [$Meshes/Papaya, COLL_TAGS.SMALL, Color.LAWN_GREEN],
	"Banana": [$Meshes/Banana, COLL_TAGS.SMALL, Color.YELLOW],
	"Dragonfruit": [$Meshes/Dragonfruit, COLL_TAGS.MED, Color.WHITE_SMOKE],
	"Peach": [$Meshes/Peach, COLL_TAGS.SMALL, Color.PEACH_PUFF],
	"Watermelon": [$Meshes/Watermelon, COLL_TAGS.LARGE, Color.DARK_ORANGE],
	"Frog Liver": [$Meshes/FrogLiver, COLL_TAGS.SMALL, Color.OLIVE],
	"Dragon Liver": [$Meshes/Liver, COLL_TAGS.LARGE, Color.MEDIUM_VIOLET_RED],
	"Cow Tongue": [$Meshes/CowTongue, COLL_TAGS.SMALL, Color.PALE_VIOLET_RED],
	"Dragon Heart": [$Meshes/Heart, COLL_TAGS.LARGE, Color.DARK_RED],
	"Butterfly Wing": [$Meshes/ButterflyWing, COLL_TAGS.SMALL, Color.BLUE_VIOLET],
	"Bumble Bee": [$Meshes/Bumblebee, COLL_TAGS.SMALL, Color.YELLOW_GREEN],
	"Dragon Tooth": [$Meshes/DragonTooth, COLL_TAGS.MED, Color.PALE_TURQUOISE],
	"Yew Bark": [$Meshes/YewBark, COLL_TAGS.MED, Color.PALE_GOLDENROD],
	"Obsidian Salt": [$Meshes/ObsidianSalt, COLL_TAGS.SMALL, Color.DARK_CYAN],
	"Guinea Pig Claw": [$Meshes/GuineaPigClaw, COLL_TAGS.SMALL, Color.LIGHT_GRAY],
	"Basilisk Horn": [$Meshes/BasiliskHorn, COLL_TAGS.HORN, Color.DARK_GRAY],
	"Processed Ingredient": [$Meshes/ProcessedIngredient, COLL_TAGS.SMALL],
}

static var danger_prefix_tags : Dictionary[DANGER_TAGS, String] = {
	DANGER_TAGS.POTENT: "Potent",
	DANGER_TAGS.ENERGETIC: "Energetic",
	DANGER_TAGS.GASEOUS: "Gaseous",
	DANGER_TAGS.ANTI: "Anti",
	DANGER_TAGS.PHASE: "Phase",
	DANGER_TAGS.EMERGENT: "Emergent",
}

static var prefix_tags : Dictionary[INGREDIENT_TAGS, String] = {
	INGREDIENT_TAGS.HEATED: "Heated",
	INGREDIENT_TAGS.CHILLED: "Chilled",
	INGREDIENT_TAGS.SOLUTION: "Solution Of",
	INGREDIENT_TAGS.SPIRITS: "Spirits Of",
	INGREDIENT_TAGS.MASHED: "Mashed",
	INGREDIENT_TAGS.UNSEEDED: "Pitted",
	INGREDIENT_TAGS.AGED: "Aged",
}

static var suffix_tags : Dictionary[INGREDIENT_TAGS, String] = {
	INGREDIENT_TAGS.POWDER: "Powder",
	INGREDIENT_TAGS.JUICE: "Juice",
	INGREDIENT_TAGS.BLEND: "Blend",
}

## a wet or fruit cannot have this tag
static var dry_only_tags : Array[INGREDIENT_TAGS] = [
	INGREDIENT_TAGS.POWDER,
]

## if the ingredient tags has one of these, remove it and replace with new one (heated -> chilled vice versa)
static var temperature_tags : Array[INGREDIENT_TAGS] = [
	INGREDIENT_TAGS.HEATED,
	INGREDIENT_TAGS.CHILLED,
]

## ingredients can only have one of these tags at a time
static var prefix_primary_tags : Array[INGREDIENT_TAGS] = [
	INGREDIENT_TAGS.MASHED,
	INGREDIENT_TAGS.AGED,
	INGREDIENT_TAGS.SOLUTION,
	INGREDIENT_TAGS.SPIRITS,
	INGREDIENT_TAGS.UNSEEDED,
]

static var suffix_primary_tags : Array[INGREDIENT_TAGS] = [
	INGREDIENT_TAGS.POWDER,
	INGREDIENT_TAGS.JUICE,
	INGREDIENT_TAGS.BLEND,
]

## a fruit can be mashed or pitted
## mashing creates mashed fruit and fruit juice
## pitting creates pitted fruit
## a pitted fruit can be mashed or blended
## a mashed fruit can be aged or blended
## a juice can be distilled to spirits
## a blend can be distilled to spirits
## a spirits can be diluted to solution
## solution can be distilled to spirits
## a dry can be blended to powder
## a powder can be diluted to solution
## a wet can be mashed or blended
## a wet mash creates wet juice???? yep
## a wet blend can be distilled and such

## only juices or blends can be distilled (spirits)
## only spirits or powders can be diluted (solution)
## only mashes can be aged (barrels)
## only unseeded (pitted) fruits or wet ingredients can be mashed (juiced)
## only mashes, pitted fruits or wet ingredients can be blended
## the blender can also powder dry ingredients
## only whole fruits can be unseeded (pitted). Produces pitted fruit

## fruit ingredients can be mashed, unseeded, juiced, chilled, heated... aged? idk
## ...organs can also be fruits
## but organs cant be unseeded :(
static var fruit_ingredients : Array[String] = [
	"Apple", ##
	"Orange", ## 
	"Papaya", ##
	"Banana", ##
	"Dragonfruit", ##
	"Peach", ##
	"Watermelon" ##
]

## organs... etc....... ig
## wets can be mashed, juice, blend, chilled, heated
static var wet_ingredients : Array[String] = [
	"Frog Liver", ##
	"Dragon Liver", ##
	"Cow Tongue", ## 
	"Dragon Heart", ##
	"Butterfly Wing", ##
	"Bumble Bee", ##
]

# dries can be powder, chilled, heated
# seeds are considered dries
static var dry_ingredients : Array[String] = [
	"Dragon Tooth", ##
	"Yew Bark", ##
	"Obsidian Salt", ##
	"Guinea Pig Claw", ##
	"Basilisk Horn", ##
]

@onready var potentEffect : MeshInstance3D = $Potent
@onready var antiEffect : MeshInstance3D = $Anti
@onready var phaseEffect : MeshInstance3D = $Phase
@onready var dangerBubble : Area3D = $RigidBody3D/DangerBubble

@onready var glowBoard : MeshInstance3D = $GlowBoard

@export_category("Ingredient Info")
@export var ingredient_tags : Array[INGREDIENT_TAGS] = []
@export var danger : Array[DANGER_TAGS] = []
@export var ingredient_type : REAGENT
@export var ingredient_id : int = -1
## creates a random ingredient based on the ingredient type.
## creates a non-random ingredient if ingredient_id is greater than -1.
@export var create_ingredient : bool = false :
	set(val):
		danger = []
		ingredient_tags = []
		# var res : Array = IngredientBase.createIngredient(
		# 	GLOBAL.current_danger_threshold, 
		# 	GLOBAL.current_process_threshold, 
		# 	true)
		var res : Array = IngredientBase.createIngredient(
			20, 
			90, 
			true)
		var ing_name : String = ""
		var ing_name_arr : Array
		var danger_tag : String = ""
		if res[2] != -1:
			danger.append(res[2])
			danger_tag = danger_prefix_tags[res[2]]
		var process_tag_id : int = -1
		if res[3] != -1:
			ingredient_tags.append(res[3])
			process_tag_id = res[3]
		var process_tag : String = ""
		var suffix_tag : String = ""
		var ing_id : int = res[0]
		var ing_type : int = res[1]
		var heat_status : int = res[4]
		var is_processed : bool = false

		if heat_status <= 20:
			ingredient_tags.append(INGREDIENT_TAGS.HEATED)
			process_tag += prefix_tags[INGREDIENT_TAGS.HEATED] + " "
		elif heat_status <= 40 && heat_status > 20:
			ingredient_tags.append(INGREDIENT_TAGS.CHILLED)
			process_tag += prefix_tags[INGREDIENT_TAGS.CHILLED] + " " 
		else:
			pass

		var __check : Array = [
			INGREDIENT_TAGS.UNSEEDED,
			INGREDIENT_TAGS.HEATED,
			INGREDIENT_TAGS.CHILLED,
		]

		for i in ingredient_tags:
			if __check.has(i):
				continue
			else:
				is_processed = true

		if prefix_tags.has(process_tag_id):
			process_tag += prefix_tags[process_tag_id] + " "
		elif suffix_tags.has(process_tag_id):
			suffix_tag += " " + suffix_tags[process_tag_id]
		
		match (ing_type):
			REAGENT.FRUIT:
				ing_name_arr = fruit_ingredients
			REAGENT.DRY:
				ing_name_arr = dry_ingredients
			REAGENT.WET:
				ing_name_arr = wet_ingredients

		# if ingredient_id == -1:
		# 	ing_id = randi() % ing_name_arr.size()
		# else:
		# 	ing_id = ingredient_id
		
		ing_name += danger_tag + " "
		ing_name += process_tag
		ing_name += ing_name_arr[ing_id]
		ing_name += suffix_tag

		for i in meshes:
			meshes[i][0].visible = false

		if is_processed:
			meshes["Processed Ingredient"][0].visible = true
			meshes["Processed Ingredient"][0].get_surface_override_material(1).set_shader_parameter("albedo", meshes[ing_name_arr[ing_id]][2])
		else:
			meshes[ing_name_arr[ing_id]][0].visible = true
		
		if res[2] != -1:
			glowBoard.mesh.size = Vector2(1, 1)
			meshes[ing_name_arr[ing_id]][0].set_material_override(dangerMaterials[res[2]])
		else:
			glowBoard.mesh.size = Vector2(0.1, 0.1)
			meshes[ing_name_arr[ing_id]][0].set_material_override(null)
		
		for i in coll:
			coll[i].disabled = true

		if is_processed:
			coll[meshes["Processed Ingredient"][1]].disabled = false
		else:
			coll[meshes[ing_name_arr[ing_id]][1]].disabled = false

			if ing_name_arr[ing_id] == "Guinea Pig Claw":
				for i in meshes[ing_name_arr[ing_id]][0].get_children():
					if res[2] != -1:
						i.set_material_override(dangerMaterials[res[2]])
					else:
						i.set_material_override(null)
		
		ingredient_name = ing_name
		ingredient_type = ing_type
		ingredient_id = ing_id
		
		
			
@export var ingredient_name : String = "Fard Flower"

var next_danger : float = 0.0
var def_danger_interval : float = 30.0
var danger_interval : float = 30.0
var mod_danger_interval : float = 15.0 # 15 seconds either way

var danger_time : float = 0.0
var max_danger_time : float = 6.0
var timed_danger : bool = false


func _ready():
	super()
	glowBoard.mesh = glowBoard.mesh.duplicate()
	dressIngredient()

func _physics_process(delta):
	super(delta)
	if !danger.is_empty() && !Engine.is_editor_hint():

		if danger[0] == DANGER_TAGS.POTENT:
			pass
		elif danger[0] == DANGER_TAGS.ANTI:
			pass
		elif danger[0] == DANGER_TAGS.PHASE:
			pass

		next_danger += delta
		glowBoard.mesh.size.x = (next_danger / danger_interval) * 1.5
		glowBoard.mesh.size.y = (next_danger / danger_interval) * 1.5

		if next_danger >= danger_interval:
			do_danger(delta)
			# do a danger
			pass
		
		if timed_danger:
			danger_time += delta
			if danger_time >= max_danger_time:
				_mainPhysObject.gravity_scale = 1.0
				antiEffect.visible = false
				potentEffect.visible = false
				phaseEffect.visible = false
				timed_danger = false
				glowBoard.mesh.size = Vector2(0.01, 0.01)
				
		pass
	pass

func do_danger(delta):
	var d_type : DANGER_TAGS = danger[0]
	if danger[0] == DANGER_TAGS.EMERGENT:
		d_type = randi() % DANGER_TAGS.size()-1 as DANGER_TAGS
	
	if d_type == DANGER_TAGS.ENERGETIC:
		if GLOBAL.player.held_object == _mainPhysObject:
			GLOBAL.player.physicsGrabbing(true)
		_mainPhysObject.linear_velocity.y += randf_range(3.5, 4.5)
		_mainPhysObject.linear_velocity.z += randf_range(-0.5, 0.5)
		_mainPhysObject.linear_velocity.y += randf_range(-0.5, 0.5)
	elif d_type == DANGER_TAGS.GASEOUS:
		if GLOBAL.player.held_object == _mainPhysObject:
			GLOBAL.player.physicsGrabbing(true)
	
		danger_time = 0.0
		timed_danger = true
		max_danger_time = 5.0
		_mainPhysObject.gravity_scale = 0.05
		glowBoard.mesh.size = Vector2(1.5, 1.5)
	elif d_type == DANGER_TAGS.ANTI:
		# creates bubble that lowers player health rapidly
		if dangerBubble.has_overlapping_bodies():
			var re : Array = dangerBubble.get_overlapping_bodies()
			var player_included : bool = false
			for i in re:
				if i == GLOBAL.player:
					player_included = true
					break
			if player_included:
				GLOBAL.takeDamage(80)
			danger_time = 0.0
			max_danger_time = 1.0
			timed_danger = true
			glowBoard.mesh.size = Vector2(1.5, 1.5)
			antiEffect.visible = true
		pass
	elif d_type == DANGER_TAGS.POTENT:
		# explodes and knocks the player back, also deals damage
		if GLOBAL.player.held_object == _mainPhysObject:
			GLOBAL.player.physicsGrabbing(true)
			GLOBAL.takeDamage(20)
			var motion : Vector3 = Vector3()
			motion.x = randf_range(-5.0, 5.0)
			motion.z = randf_range(-5.0, 5.0)
			motion.y = randf_range(5.0, 10.0)
			GLOBAL.player.velocity += motion
		danger_time = 0.0
		max_danger_time = 1.5
		timed_danger = true
		glowBoard.mesh.size = Vector2(1.5, 1.5)
		potentEffect.visible = true
		pass
	elif d_type == DANGER_TAGS.PHASE:
		if GLOBAL.player.held_object == _mainPhysObject:
			GLOBAL.player.physicsGrabbing(true)
		# the ingredient moves in a random direction
		danger_time = 0.0
		max_danger_time = 3.0
		timed_danger = true
		glowBoard.mesh.size = Vector2(1.5, 1.5)
		phaseEffect.visible = true
		var motion : Vector3 = Vector3()
		motion.x = randf_range(-2.0, 2.0)
		motion.z = randf_range(-2.0, 2.0)
		motion.y = randf_range(0.0, 2.0)
		_mainPhysObject.move_and_collide(motion)
	
	
	danger_interval = def_danger_interval + randf_range(-mod_danger_interval, mod_danger_interval)
	next_danger = 0.0

func _process(delta):
	if danger.is_empty():
		return

	if danger[0] == DANGER_TAGS.ENERGETIC:
		$Meshes.position.x = randf() * 0.01
		$Meshes.position.z = randf() * 0.01
		$Meshes.position.y = randf() * 0.01
	pass

func resetProcess():
	ingredient_tags.clear()
	pass

func addProcess(id : INGREDIENT_TAGS):
	var reverse_id : int = -1
	if id == INGREDIENT_TAGS.CHILLED:
		reverse_id = INGREDIENT_TAGS.HEATED
	elif id == INGREDIENT_TAGS.HEATED:
		reverse_id = INGREDIENT_TAGS.CHILLED
	
	# just a temp thing then
	if reverse_id > -1:
		ingredient_tags.erase(reverse_id)
		ingredient_tags.erase(id)
		ingredient_tags.append(id)
		dressIngredient()
		return
	# not a temperature thing

	for i in ingredient_tags:
		if i == INGREDIENT_TAGS.CHILLED || i == INGREDIENT_TAGS.HEATED:
			continue
		reverse_id = i
	
	# the ingredient was processed. hooraaay!!! 0 and 1 are chilled/heated.
	if reverse_id > 1:
		ingredient_tags.erase(reverse_id)
	
	ingredient_tags.append(id)
	dressIngredient()


func dressIngredient():
	var prefix_tag : String = ""
	var suffix_tag : String = ""
	var ing_name_arr : Array = []
	var ing_name : String = ""
	var is_processed : bool = false

	for i in danger:
		prefix_tag += danger_prefix_tags[i] + " "

	var __check : Array = [
		INGREDIENT_TAGS.UNSEEDED,
		INGREDIENT_TAGS.HEATED,
		INGREDIENT_TAGS.CHILLED,
	]

	print("yolo   ", ingredient_tags)

	if ingredient_tags.has(INGREDIENT_TAGS.HEATED):
		prefix_tag += prefix_tags[INGREDIENT_TAGS.HEATED] + " "
	elif ingredient_tags.has(INGREDIENT_TAGS.CHILLED):
		prefix_tag += prefix_tags[INGREDIENT_TAGS.CHILLED] + " " 

	for i in ingredient_tags:
		if __check.has(i):
			pass
		else:
			is_processed = true
		if i == INGREDIENT_TAGS.CHILLED || i == INGREDIENT_TAGS.HEATED:
			continue
		if prefix_tags.has(i):
			prefix_tag += prefix_tags[i] + " "
		elif suffix_tags.has(i):
			suffix_tag += " " + suffix_tags[i]
		
	match (ingredient_type):
		REAGENT.FRUIT:
			ing_name_arr = fruit_ingredients
		REAGENT.DRY:
			ing_name_arr = dry_ingredients
		REAGENT.WET:
			ing_name_arr = wet_ingredients
	
	ing_name += prefix_tag
	ing_name += ing_name_arr[ingredient_id]
	ing_name += suffix_tag

	for i in meshes:
		meshes[i][0].visible = false

	if is_processed:
		meshes["Processed Ingredient"][0].set_surface_override_material(0, generalHatchMaterial.duplicate())
		meshes["Processed Ingredient"][0].set_surface_override_material(1, waterHatchMaterial.duplicate())
		meshes["Processed Ingredient"][0].visible = true
		meshes["Processed Ingredient"][0].get_surface_override_material(1).set_shader_parameter("albedo", meshes[ing_name_arr[ingredient_id]][2])
	else:
		meshes[ing_name_arr[ingredient_id]][0].visible = true

	print(meshes[ing_name_arr[ingredient_id]][0].get_material_override())
	if danger.size() > 0:
		glowBoard.mesh.size = Vector2(1, 1)
		meshes[ing_name_arr[ingredient_id]][0].set_material_override(dangerMaterials[danger[0]])
	else:
		glowBoard.mesh.size = Vector2(0.1, 0.1)
		meshes[ing_name_arr[ingredient_id]][0].set_material_override(null)
	
	for i in coll:
		coll[i].disabled = true

	if is_processed:
		coll[meshes["Processed Ingredient"][1]].disabled = false
	else:
		coll[meshes[ing_name_arr[ingredient_id]][1]].disabled = false

		if ing_name_arr[ingredient_id] == "Guinea Pig Claw":
			for i in meshes[ing_name_arr[ingredient_id]][0].get_children():
				if danger.size() > 0:
					i.set_material_override(dangerMaterials[danger[0]])
				else:
					i.set_material_override(null)
	
	ingredient_name = ing_name
	prop_name = ing_name
	prop_desc = "Pure " + ing_name_arr[ingredient_id] + "."
		

func setCustomIngredientStuff(_id : int, _type : REAGENT, _danger : Array = [], _processes : Array = []):
	ingredient_tags.clear()
	danger.clear()
	var process_tag : String = ""
	var suffix_tag : String = ""
	var full_ing_name : String = ""
	var ing_type : REAGENT = _type
	var danger_tag : String = ""
	var ing_id : int = _id
	var ing_name_arr : Array

	match (ing_type):
		REAGENT.FRUIT:
			ing_name_arr = fruit_ingredients
		REAGENT.DRY:
			ing_name_arr = dry_ingredients
		REAGENT.WET:
			ing_name_arr = wet_ingredients
	
	if !_danger.is_empty():
		var danger_id : DANGER_TAGS = _danger[0]
		danger_tag = danger_prefix_tags[danger_id]

	if _processes.size() > 0:
		if _processes.has(INGREDIENT_TAGS.HEATED):
			process_tag += prefix_tags[INGREDIENT_TAGS.HEATED] + " "
		elif _processes.has(INGREDIENT_TAGS.CHILLED):
			process_tag += prefix_tags[INGREDIENT_TAGS.CHILLED] + " " 
		for i in _processes:
			if i == INGREDIENT_TAGS.CHILLED || i == INGREDIENT_TAGS.HEATED:
				continue
			if prefix_tags.has(i):
				process_tag += prefix_tags[i] + " "
			elif suffix_tags.has(i):
				suffix_tag += suffix_tags[i]
	
	full_ing_name += danger_tag + " " if danger_tag.length() > 0 else ""
	full_ing_name += process_tag if process_tag.length() > 0 else ""
	full_ing_name += ing_name_arr[ing_id]
	full_ing_name += " " + suffix_tag if suffix_tag.length() > 0 else ""

	ingredient_tags.clear()

	ingredient_id = ing_id
	ingredient_type = ing_type
	ingredient_name = full_ing_name
	for i in _processes:
		ingredient_tags.append(i)
	for i in _danger:
		danger.append(i)
	
	call_deferred("dressIngredient")



static func createIngredient(danger_limit : int = 80, process_limit : int = 20, fordaingredient : bool = false):
	var heat_status : int = randi() % 100
	var process_tag : String = ""
	var suffix_tag : String = ""
	var full_ing_name : String = ""
	var ing_type : REAGENT = randi() % REAGENT.size() as REAGENT
	var should_process : int = randi() % 100
	var has_danger : int = randi() % 100
	var danger_tag : String = ""
	var ing_id : int
	var ing_name_arr : Array

	match (ing_type):
		REAGENT.FRUIT:
			ing_name_arr = fruit_ingredients
		REAGENT.DRY:
			ing_name_arr = dry_ingredients
		REAGENT.WET:
			ing_name_arr = wet_ingredients
	
	ing_id = randi() % ing_name_arr.size()

	if heat_status <= 20:
		process_tag += prefix_tags[INGREDIENT_TAGS.HEATED] + " "
	elif heat_status <= 40 && heat_status > 20:
		process_tag += prefix_tags[INGREDIENT_TAGS.CHILLED] + " " 
	else:
		pass
	
	var danger_id : int = -1

	if has_danger > danger_limit:
		danger_id = randi() % danger_prefix_tags.size()
		danger_tag = danger_prefix_tags[danger_id]

	var process_id : int = -1

	if should_process > process_limit:
		# need to add random processed effect
		var trying_process : bool = true

		while trying_process:
			process_id = randi() % INGREDIENT_TAGS.size()
			if process_id == INGREDIENT_TAGS.HEATED || process_id == INGREDIENT_TAGS.CHILLED: # no heat/chills
				continue
			if ing_type != REAGENT.DRY && process_id == INGREDIENT_TAGS.POWDER: # only dries can be powder
				continue
			if ing_type != REAGENT.FRUIT && process_id == INGREDIENT_TAGS.UNSEEDED: # only fruits can be pitted
				continue
			if ing_type == REAGENT.DRY && process_id == INGREDIENT_TAGS.AGED: # anything... can be aged......
				continue
			if ing_type == REAGENT.DRY && process_id == INGREDIENT_TAGS.MASHED:
				continue
			if ing_type == REAGENT.DRY && process_id == INGREDIENT_TAGS.BLEND:
				process_id = INGREDIENT_TAGS.POWDER
			if ing_type == REAGENT.DRY && process_id == INGREDIENT_TAGS.JUICE:
				continue
			

		
			if prefix_tags.has(process_id):
				process_tag += prefix_tags[process_id] + " "
			elif suffix_tags.has(process_id):
				suffix_tag += suffix_tags[process_id]
			trying_process = false


	full_ing_name += danger_tag + " " if danger_tag.length() > 0 else ""
	full_ing_name += process_tag if process_tag.length() > 0 else ""
	full_ing_name += ing_name_arr[ing_id]
	full_ing_name += " " + suffix_tag if suffix_tag.length() > 0 else ""

	if fordaingredient:
		# print("did for da ingredient boooi")
		# print([ing_id, ing_type, danger_id, process_id, heat_status, full_ing_name])
		return [ing_id, ing_type, danger_id, process_id, heat_status, full_ing_name]
	return [ing_id, ing_type, full_ing_name]

	# now test
