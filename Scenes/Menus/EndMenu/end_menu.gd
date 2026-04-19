extends Control

@onready var tryAgainButton : Button = $Panel/VBoxContainer/TryAgain
@onready var quitButton : Button = $Panel/VBoxContainer/Quit
@onready var loseText : Label = $Panel/VBoxContainer/Lose
@onready var winText : Label = $Panel/VBoxContainer/Win


func _ready():
	tryAgainButton.pressed.connect(tryAgain)
	quitButton.pressed.connect(quit)


func gameEnded(won : bool):
	loseText.visible = !won
	winText.visible = won


func tryAgain():
	visible = false
	GLOBAL.resetGame()
	get_tree().change_scene_to_file("res://Scenes/Main/main.tscn")


func quit():
	GLOBAL.quitGame()
	pass
