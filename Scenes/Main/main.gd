extends Node3D

@onready var playerSpawn : Node3D = $PlayerSpawn
@onready var ingredientSpawns : Node3D = $Ingredients
@onready var potionHolder : Node3D = $Potion
@onready var teleporter : Area3D = $Teleporter

func _ready():
	GLOBAL.mainScene = self
	GLOBAL.playerHolder = playerSpawn
	GLOBAL.ingredientHolder = ingredientSpawns
	GLOBAL.potionHolder = potionHolder
	teleporter.body_entered.connect(teleportStuff)



func beginGame():
	GLOBAL.player.beginGame()
	

func teleportStuff(body):
	if body == GLOBAL.player:
		GLOBAL.player.velocity = Vector3()
		GLOBAL.player.global_position = playerSpawn.global_position
		return
	
	var p = body.get_parent()

	if p is PotionBase:
		# teleport potion back to spawn
		body.linear_velocity = Vector3()
		body.global_position = potionHolder.global_position
	
	if p is IngredientBase: # same thing
		body.linear_velocity = Vector3()
		body.global_position = potionHolder.global_position
		pass
	pass


func resetPlayer():
	GLOBAL.player.global_position = playerSpawn.global_position
	GLOBAL.player.resetPlayer()


