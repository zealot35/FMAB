extends Control

@onready var playButton : Button = $Panel/VBoxContainer/Play
@onready var continueButton : Button = $Panel/VBoxContainer/Resume
@onready var how2PlayButton : Button = $Panel/VBoxContainer/How2Play
@onready var rerollButton : Button = $Panel/VBoxContainer/RerollPotion
@onready var settingsButton : Button = $Panel/VBoxContainer/Settings
@onready var attriButton : Button = $Panel/VBoxContainer/Attributions
@onready var quitButton : Button = $Panel/VBoxContainer/Quit

@onready var optionMenu : Panel = $Option
@onready var attribMenu : Panel = $Attribution
@onready var how2PlayMenu : Panel = $How2Play

func _ready():
	playButton.pressed.connect(playPressed)
	continueButton.pressed.connect(continuePressed)
	quitButton.pressed.connect(quitPressed)
	settingsButton.pressed.connect(settingsPressed)
	attriButton.pressed.connect(attribPressed)
	how2PlayButton.pressed.connect(how2PlayPressed)
	rerollButton.pressed.connect(rerollPressed)
	pass

func _physics_process(_delta):
	playButton.visible = !GLOBAL.in_game
	rerollButton.visible = GLOBAL.in_game
	continueButton.visible = GLOBAL.in_game

func playPressed():
	self.visible = !self.visible
	GLOBAL.beginGame()

func continuePressed():
	self.visible = !self.visible
	GLOBAL.player.toggleMouselock(!self.visible)

func how2PlayPressed():
	how2PlayMenu.visible = !how2PlayMenu.visible
	optionMenu.visible = false
	attribMenu.visible = false
	pass

func rerollPressed():
	GLOBAL.resetPotion()

func settingsPressed():
	optionMenu.visible = !optionMenu.visible
	how2PlayMenu.visible = false
	attribMenu.visible = false
	pass

func attribPressed():
	attribMenu.visible = !attribMenu.visible
	optionMenu.visible = false
	how2PlayMenu.visible = false
	pass

func quitPressed():
	GLOBAL.quitGame()


