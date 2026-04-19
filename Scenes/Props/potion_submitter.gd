extends PropBase

@onready var inputArea : Area3D = $Input
@onready var particles : GPUParticles3D = $GPUParticles3D
@onready var success : AudioStreamPlayer3D = $Success

func _ready():
	super()
	inputArea.body_entered.connect(inputEntered)



func inputEntered(body):
	var p = body.get_parent()

	if !p is PotionBase:
		return
	
	# if this somehow happens i will pull my hair out
	if p != GLOBAL.current_potion:
		return
	
	GLOBAL.removePotion()
	GLOBAL.resetPotion()
	GLOBAL.raiseDifficulty()
	doEffect()

	# delete potion, put up particle, increase difficulty, generate new potion

func doEffect():
	success.play()
	particles.emitting = true
	pass

