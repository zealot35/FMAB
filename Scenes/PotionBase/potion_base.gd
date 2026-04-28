@tool
extends PropBase
class_name PotionBase

# potions require a set of ingredients with specific tags applied to them
# potions are randomly generated, both in their ingredients and "effect"
# "effect" is just random bs
# the ACTUAL potion mechanic comes from not dropping/banging around the finished product

static var potion_prefixes : Array = [
	"Elucidating",
	"Asphyxiating",
	"Luxurious",
	"Incredible",
	"Infallible",
	"Arduous",
	"Excruciating",
	"Fascinating",
	"Useless",
	"Appealing",
	"Cantankerous",
	"Arousing",
	"Informative",
	"Unassuming",
	"Weak",
	"Strong",
	"Absolute",
	"Normal",
	"Common",
	"Average",
	"Trembling",
	"Sticky",
	"Slippery",
	"Sappy",
	"Weird",
	"Spooky",
	"Intense",
	"Gassy",
	"Lubricating",
	"Relaxing",
	"Subtle",
	"Strange",
	"Fortifying",
	"Luminous",
	"Perilous",
	"Hairy",
	"Explosive",
	"Deafening",
	"Delicious",
	"Disgusting",
	"Sour",
	"Weary",
	"Dizzying",
	"Violent",
	"Subdued",
	"Bottomless",
]

static var potion_types : Array = [
	"Brew",
	"Elixir",
	"Potion",
	"Flask",
	"Concoction",
	"Substance",
	"Wine",
	"Liquid",
	"Essence",
	"Extract",
	"Pint",
	"Cider",
	"Smoothie",
	"Globule",
	"Pot",
]

static var potion_suffixes : Array = [
	"Of Healing",
	"Of Harming",
	"Of Farting",
	"Of Invisibility",
	"Of Uselessness",
	"Of Weakness",
	"Of Poisoning",
	"Of Triage",
	"Of Mage Sight",
	"Of Wizard Hearing",
	"Of Barbaric Strength",
	"Of Archery",
	"Of Elongation",
	"Of Skill",
	"Of Mind Wiping",
	"Of Regrowth",
	"Of Fortifications",
	"Of Blocking",
	"Of Reassurance",
	"Of Energy",
	"Of... Something",
	"Of Sillyness",
	"Of Watery Demise",
	"Of Drowning",
	"Of Double Enthusiastic Diarrhea",
	"Of Witchcraft",
	"Of Lying",
	"Of Truthseeking",
	"Of Sickness",
	"Of Puking",
	"Of Defecating",
	"Of Nothing",
	"Of Tastiness",
	"Of Deliciousness",
	"Of Sourness",
	"Of Sorrow",
	"Of Flavor",
	"Of Mortality",
	"Of Weak Will",
	"Of Disco",
	"Of Dancing",
	"Of Two Left Feet",
	"Of Hunger",
	"Of Murphy",
	"Of Burping",
	"Of Random Luck",
	"Of Scrambling",
	"Of Grass",
	"Of Leprechaun",
	"Of Sleeping",
	"Of Real",
	"Of Fishing",
	"Of Smithing",
	"Of Butchery",
	"Of Tinnitus",
	"Of Hatching",
	"Of Axing",
	"Of Axes",
	"Of Body Spray",
	"Of Yellow",
	"Of Reckoning",
	"Of Larping",
	"Of Wizardry",
	"Of Feeding",
	"Of Eating",
	"Of Dressing",
	"Of Singing",
	"Of Belching",
	"Of Screeching",
	"Of Hearing Loss",
	"Of Echolocation",
	"Of Spirits",
	"Of Time",
	"Of Transformation",
	"Of Immorality. Yes, That's Spelled Right",
]

static var potion_specials : Array = [
	"IT BURNS",
	"Late Night Brew",
	"Whining Wine",
	"Wizard Backwash",
	"Funny Business",
	"Clown Juice",
	"Biscuit",
]

static var potion_descs : Array = [
	"This bottle contains something far beyond your comprehension...",
	"It's whispering.",
	"You feel a tremendous urge to drink it...",
	"...You'd rather not talk about it.",
	"Maybe you shouldn't have made this one...",
	"It smells like roses.",
	"It smells like... nevermind.",
	"You wonder how all of those ingredients could fit in this bottle.",
	"It's emitting the faint sound of the ocean.",
	"A mere sniff makes you angry beyond reason.",
	"It might be glue.",
	"Snozzberries.",
	"Chaos.",
	"Perhaps it's best to let the mystical arts remain a mystery.",
	"It leaves a nice chocolate-ly aftertaste.",
	"It appears to be made out of wax.",
	"Somewhere within, your next paycheck awaits.",
]


@onready var meshes : Array = [
	$RigidBody3D/Meshes/Potion1,
	$RigidBody3D/Meshes/Potion2,
	$RigidBody3D/Meshes/Potion3,
	$RigidBody3D/Meshes/Potion4,
]


## recipe bro cmon bro just cmon brho 
@export var recipe : Array[String] = []
## raw ingredients
@export var used_ingredients : Array = []
## number of ingredients for the recipe
@export var ingredient_count : int = 1
## rng over this threshold will create a dangerous ingredient
@export var danger_threshold : int = 80
## rng over this threshold will create a processed ingredient
@export var process_threshold : int = 20
## potion name
@export var potion_name : String = ""
## uses danger limit, process limit and ingredient count to generate a list of recipes
@export var cast_recipe : bool = false :
	set(val):
		recipe = []
		used_ingredients = []
		for i in meshes:
			i.visible = false
		selected_mesh = meshes[randi() % meshes.size()]
		selected_mesh.visible = true
		# Color.from_string()
		var color_name : String = color_names[randi() % color_names.size()]
		var glass_col : Color = Color.from_string(color_name, Color.WHITE)
		glass_col.a = 0.25
		var liquid_col : Color = Color.from_string(color_names[randi() % color_names.size()], Color.WHITE)
		var foam_col : Color = Color.from_string(color_names[randi() % color_names.size()], Color.WHITE)
		print(color_name, "  ", glass_col)
		glassMaterial.set_shader_parameter("albedo", glass_col)
		liquidShaderMaterial.set_shader_parameter("liquid_color", liquid_col)
		liquidShaderMaterial.set_shader_parameter("foam_color", foam_col)
		liquidShaderMaterial.set_shader_parameter("HasBubbles", randi() % 2)
		liquidShaderMaterial.set_shader_parameter("AlwaysBubbles", randi() % 2)
		liquidShaderMaterial.set_shader_parameter("BubbleStrength", clamp(randf(), 0.2, 0.9))
		liquidShaderMaterial.set_shader_parameter("foam_line", clamp(randf()-0.5, 0.0, 0.4))
		liquidShaderMaterial.set_shader_parameter("fill_amount", 0.5)

		liquidShaderMaterial = liquidShaderMaterial.duplicate_deep()
		selected_mesh.set_surface_override_material(0, glassMaterial)
		selected_mesh.get_surface_override_material(0).next_pass = liquidShaderMaterial

		for i in ingredient_count:
			var ing : Array = IngredientBase.createIngredient(danger_threshold, process_threshold)
			used_ingredients.append([ing[0], ing[1]])
			recipe.append(ing[2])
		
		potion_name = PotionBase.createCustomPotionName()
		pass
## prints out base ingredients
@export var explain_benefits : bool = false :
	set(val):
		for i in used_ingredients:
			var ing_name_arr : Array

			match (i[1]):
				IngredientBase.REAGENT.FRUIT:
					ing_name_arr = IngredientBase.fruit_ingredients
				IngredientBase.REAGENT.DRY:
					ing_name_arr = IngredientBase.dry_ingredients
				IngredientBase.REAGENT.WET:
					ing_name_arr = IngredientBase.wet_ingredients

			print(ing_name_arr[i[0]])

		pass
	

var selected_mesh : MeshInstance3D

@export_group("Child Dependencies")
@export var liquidShaderMaterial: ShaderMaterial
@export var glassMaterial: ShaderMaterial

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
	super()
	if liquidShaderMaterial == null:
		return
	liquidShaderMaterial = liquidShaderMaterial.duplicate()
	for i in meshes:
		if i.visible:
			selected_mesh = i
			break
	selected_mesh.set_surface_override_material(0, selected_mesh.get_surface_override_material(0).duplicate())
	selected_mesh.get_surface_override_material(0).next_pass = liquidShaderMaterial

func _physics_process(delta):
	super(delta)
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


func setName(_n : String):
	prop_name = _n
	potion_name = _n
	prop_desc = potion_descs[randi() % potion_descs.size()]


func setMeshStuff():
	for i in meshes:
		i.visible = false
	selected_mesh = meshes[randi() % meshes.size()]
	selected_mesh.visible = true
	# Color.from_string()
	var color_name : String = color_names[randi() % color_names.size()]
	var glass_col : Color = Color.from_string(color_name, Color.WHITE)
	glass_col.a = 0.25
	var liquid_col : Color = Color.from_string(color_names[randi() % color_names.size()], Color.WHITE)
	var foam_col : Color = Color.from_string(color_names[randi() % color_names.size()], Color.WHITE)
	print(color_name, "  ", glass_col)
	glassMaterial.set_shader_parameter("albedo", glass_col)
	liquidShaderMaterial.set_shader_parameter("liquid_color", liquid_col)
	liquidShaderMaterial.set_shader_parameter("foam_color", foam_col)
	liquidShaderMaterial.set_shader_parameter("HasBubbles", randi() % 2)
	liquidShaderMaterial.set_shader_parameter("AlwaysBubbles", randi() % 2)
	liquidShaderMaterial.set_shader_parameter("BubbleStrength", clamp(randf(), 0.2, 0.9))
	liquidShaderMaterial.set_shader_parameter("foam_line", clamp(randf()-0.5, 0.0, 0.4))
	liquidShaderMaterial.set_shader_parameter("fill_amount", 0.5)

	liquidShaderMaterial = liquidShaderMaterial.duplicate_deep()
	selected_mesh.set_surface_override_material(0, glassMaterial)
	selected_mesh.get_surface_override_material(0).next_pass = liquidShaderMaterial


## [ing_id, ing_type, danger_id, process_id, heat_status, full_ing_name]
static func generateCustomPotionIngredients() -> Array:
	var _dif : int = GLOBAL.difficulty # number of ingredients to choose, process and danger thresholds
	var _dt : int = 100 - (_dif*5)
	var _pt : int = 100 - (_dif*10)

	var _ing_count : int = maxi(1, randi() % 3 + (_dif / 2))

	var _recipe : Array = []

	# [ing_id, ing_type, danger_id, process_id, heat_status, full_ing_name]
	# [ing_id, ing_type, full_ing_name]

	for i in _ing_count:
		var ing : Array = IngredientBase.createIngredient(_dt, _pt, true)
		_recipe.append(ing)

	return _recipe
 

static func createCustomPotionName() -> String:
	var r : int = randi() % 100
	var using_special_name : bool = false
	if r > 98: # 2% chance
		using_special_name = true
	
	var _name : String = ""

	if using_special_name:
		_name = potion_specials[randi() % potion_specials.size()]
	else:
		var pre : String = potion_prefixes[randi() % potion_prefixes.size()]
		var pot : String = potion_types[randi() % potion_types.size()]
		var suf : String = potion_suffixes[randi() % potion_suffixes.size()]

		_name = pre + " " + pot + " " + suf
	
	return _name



static var color_names : Array = [
	"ALICE_BLUE",
	"ANTIQUE_WHITE",
	"AQUA",
	"AQUAMARINE",
	"AZURE",
	"BEIGE",
	"BISQUE",
	"BLACK",
	"BLANCHED_ALMOND",
	"BLUE",
	"BLUE_VIOLET",
	"BROWN",
	"BURLYWOOD",
	"CADET_BLUE",
	"CHARTREUSE",
	"CHOCOLATE",
	"CORAL",
	"CORNFLOWER_BLUE",
	"CORNSILK",
	"CRIMSON",
	"CYAN",
	"DARK_BLUE",
	"DARK_CYAN",
	"DARK_GOLDENROD",
	"DARK_GRAY",
	"DARK_GREEN",
	"DARK_KHAKI",
	"DARK_MAGENTA",
	"DARK_OLIVE_GREEN",
	"DARK_ORANGE",
	"DARK_ORCHID",
	"DARK_RED",
	"DARK_SALMON",
	"DARK_SEA_GREEN",
	"DARK_SLATE_BLUE",
	"DARK_SLATE_GRAY",
	"DARK_TURQUOISE",
	"DARK_VIOLET",
	"DEEP_PINK",
	"DEEP_SKY_BLUE",
	"DIM_GRAY",
	"DODGER_BLUE",
	"FIREBRICK",
	"FLORAL_WHITE",
	"FOREST_GREEN",
	"FUCHSIA",
	"GAINSBORO",
	"GHOST_WHITE",
	"GOLD",
	"GOLDENROD",
	"GRAY",
	"GREEN",
	"GREEN_YELLOW",
	"HONEYDEW",
	"HOT_PINK",
	"INDIAN_RED",
	"INDIGO",
	"IVORY",
	"KHAKI",
	"LAVENDER",
	"LAVENDER_BLUSH",
	"LAWN_GREEN",
	"LEMON_CHIFFON",
	"LIGHT_BLUE",
	"LIGHT_CORAL",
	"LIGHT_CYAN",
	"LIGHT_GOLDENROD",
	"LIGHT_GRAY",
	"LIGHT_GREEN",
	"LIGHT_PINK",
	"LIGHT_SALMON",
	"LIGHT_SEA_GREEN",
	"LIGHT_SKY_BLUE",
	"LIGHT_SLATE_GRAY",
	"LIGHT_STEEL_BLUE",
	"LIGHT_YELLOW",
	"LIME",
	"LIME_GREEN",
	"LINEN",
	"MAGENTA",
	"MAROON",
	"MEDIUM_AQUAMARINE",
	"MEDIUM_BLUE",
	"MEDIUM_ORCHID",
	"MEDIUM_PURPLE",
	"MEDIUM_SEA_GREEN",
	"MEDIUM_SLATE_BLUE",
	"MEDIUM_SPRING_GREEN",
	"MEDIUM_TURQUOISE",
	"MEDIUM_VIOLET_RED",
	"MIDNIGHT_BLUE",
	"MINT_CREAM",
	"MISTY_ROSE",
	"MOCCASIN",
	"NAVAJO_WHITE",
	"NAVY_BLUE",
	"OLD_LACE",
	"OLIVE",
	"OLIVE_DRAB",
	"ORANGE",
	"ORANGE_RED",
	"ORCHID",
	"PALE_GOLDENROD",
	"PALE_GREEN",
	"PALE_TURQUOISE",
	"PALE_VIOLET_RED",
	"PAPAYA_WHIP",
	"PEACH_PUFF",
	"PERU",
	"PINK",
	"PLUM",
	"POWDER_BLUE",
	"PURPLE",
	"REBECCA_PURPLE",
	"RED",
	"ROSY_BROWN",
	"ROYAL_BLUE",
	"SADDLE_BROWN",
	"SALMON",
	"SANDY_BROWN",
	"SEA_GREEN",
	"SEASHELL",
	"SIENNA",
	"SILVER",
	"SKY_BLUE",
	"SLATE_BLUE",
	"SLATE_GRAY",
	"SNOW",
	"SPRING_GREEN",
	"STEEL_BLUE",
	"TAN",
	"TEAL",
	"THISTLE",
	"TOMATO",
	# "TRANSPARENT" fuck you transparent,
	"TURQUOISE",
	"VIOLET",
	"WEB_GRAY",
	"WEB_GREEN",
	"WEB_MAROON",
	"WEB_PURPLE",
	"WHEAT",
	"WHITE",
	"WHITE_SMOKE",
	"YELLOW",
	"YELLOW_GREEN",
]
