extends Node

var debug_mode : bool = false

var in_game : bool = false

var ingredient_scene := preload("res://Scenes/IngredientBase/IngredientBase.tscn")
var potion_scene := preload("res://Scenes/PotionBase/PotionBase.tscn")

var mainScene
var player
var ingredientHolder : Node3D
var playerHolder
var potionCrafter
var potionHolder

var current_potion : PotionBase

var current_danger_threshold : int = 80
var current_process_threshold : int = 50

@onready var debugUI : Label = $DebugUI
@onready var inspectorName : Label = $HoverParent/HoverHoriz/InspectorParent/InspectorName
@onready var inspectorDesc : Label = $HoverParent/HoverHoriz/InspectorParent/InspectorDesc
@onready var hover : Control = $HoverParent
@onready var recipePage : Control = $RecipePage
@onready var damageScreen : Panel = $Damage
@onready var mainMenu : Control = $MainMenu
@onready var endMenu : Control = $EndMenu
@onready var musicPlayer : AudioStreamPlayer = $MusicPlayer
@onready var healthBar : ProgressBar = $HealthBar
@onready var music : Array = [
	[load("res://Resources/Sounds/Music/ballad_of_two_bards.mp3"), 86, 89],
	[load("res://Resources/Sounds/Music/by_a_campfire.mp3"), 80, 85],
	[load("res://Resources/Sounds/Music/lurking.mp3"), 98, 100],
	[load("res://Resources/Sounds/Music/Sticks.mp3"), 70, 79],
	[load("res://Resources/Sounds/Music/tune_a_fish.mp3"), 40, 59],
	[load("res://Resources/Sounds/Music/crunchy_leaves.mp3"), 60, 69],
	[load("res://Resources/Sounds/Music/vibrant_final.mp3"), 90, 97],
]

var music_interval : float = 15.0
var next_music : float = 0.0
var playing_music : bool = false
var last_song : int = -1
var health : int = 100
var difficulty : int = 1
var heal_tick : float = 0.0

var potions_complete : int = 0
var max_potions : int = 11

func _ready():
	musicPlayer.finished.connect(musicFinished)
	if !debug_mode:
		debugUI.visible = false


func _physics_process(delta):
	if !playing_music:
		next_music += delta

		if next_music >= music_interval:
			playDatMusicFunkyWhiteBoy()
			next_music = 0.0
	
	if damageScreen.self_modulate.a > 0.0:
		damageScreen.self_modulate.a = move_toward(damageScreen.self_modulate.a, 0.0, delta*2)

	if !in_game:
		return
	
	if health < 100:
		heal_tick += delta

		if heal_tick >= 1.5:
			health += 1
			heal_tick = 0.0

	if Input.is_action_pressed("recipe"):
		# while input is held, lerp page over
		recipePage.position.x = move_toward(recipePage.position.x, 0.0, delta*800)
		pass
	else:
		recipePage.position.x = move_toward(recipePage.position.x, get_viewport().get_visible_rect().size.x/2, delta*800)
		

	healthBar.value = health
	health = clampi(health, 0, 100)

	if health <= 0:
		endGame(false)
	if potions_complete >= max_potions:
		endGame(true)

	pass


func resetGame():
	health = 100
	hover.disabled = false
	difficulty = 1
	healthBar.visible = false
	mainMenu.visible = true
	recipePage.visible = false
	potions_complete = 0
	pass

func takeDamage(dmg : int):
	damageScreen.self_modulate.a = 1.0
	health -= dmg
	health = clampi(health, 0, 100)


func endGame(win : bool):
	hover.disabled = true
	in_game = false
	player.toggleMouselock(false)
	endMenu.visible = true
	endMenu.gameEnded(win)
	mainMenu.visible = false


func playDatMusicFunkyWhiteBoy():
	var r : int = randi() % 100
	var playing_something : bool = false
	for e in music.size():
		var i : Array = music[e]
		if r >= i[1] && r <= i[2]:
			if last_song == e:
				continue
			last_song = e
			print("we are playing: ", i)
			musicPlayer.stream = i[0]
			musicPlayer.play()
			playing_music = true
			playing_something = true
			pass
			break
	if !playing_something:
		print("we didn't play anything vro")
	pass


func musicFinished():
	playing_music = false


func set_inspector_alpha(alpha : float = 1.0):
	inspectorDesc.self_modulate.a = alpha
	inspectorName.self_modulate.a = alpha


func beginGame():
	mainScene.beginGame()
	recipePage.potionCount.text = "Potions Crafted: " + str(potions_complete) + " / " +str(max_potions) + "\n"
	recipePage.visible = true
	healthBar.visible = true
	spawnIngredients()
	in_game = true


func removePotion():
	# assume we did a good
	potions_complete += 1
	recipePage.potionCount.text = "Potions Crafted: " + str(potions_complete) + " / " +str(max_potions) + "\n"
	current_potion.queue_free()
	current_potion = null
	pass


func raiseDifficulty():
	difficulty += 1
	difficulty = clampi(difficulty, 1, 10)
	pass


func spawnPotion():
	potionHolder.add_child(current_potion)
	current_potion.setMeshStuff()
	current_potion._mainPhysObject.global_position = potionCrafter.output.global_position
	current_potion._mainPhysObject.linear_velocity.y -= 1.0

	pass


func resetPotion():
	clearIngredients()
	
	spawnIngredients()


func clearIngredients():
	for i in ingredientHolder.get_children():
		i.queue_free()


func spawnIngredients():
	# var potion : PotionBase = potion_scene.instantiate()
	# generate some ingredients for the potion

	# [ing_id, ing_type, danger_id, process_id, heat_status, full_ing_name]

	current_potion = potion_scene.instantiate()
	current_potion.setName(PotionBase.createCustomPotionName())

	var arr : Array = PotionBase.generateCustomPotionIngredients()
	var _spawns : Array = get_tree().get_nodes_in_group("ingredient_spawn")

	var cut_arr : Array[String] = []
	var potion_names : String = ""

	print(arr)

	for i in arr:
		cut_arr.append(i[5])
		potion_names += i[5] + "\n"
		# create ingredients and spawn them around
		var ing : IngredientBase = ingredient_scene.instantiate()
		ingredientHolder.add_child(ing)
		var _dangers : Array = []
		if i[2] > -1:
			_dangers.append(i[2])
		print(_dangers)
		var ing_id : int = i[0]
		var ing_type : int = i[1]
		ing.setCustomIngredientStuff(ing_id, ing_type, _dangers)
		var rand_spawn : Vector3 = _spawns[randi() % _spawns.size()].global_position
		print(rand_spawn)
		ing._mainPhysObject.global_position = rand_spawn
	
	current_potion.recipe = cut_arr

	recipePage.potionName.text = "Potion:\n" + current_potion.potion_name
	
	recipePage.potionIngredients.text = potion_names


func quitGame():
	get_tree().quit()
