extends Control

var target : Vector3 = Vector3.ZERO
var focused : bool = false
var disabled : bool = false

@onready var cursor : TextureRect = $HoverHoriz/Cursor
@onready var inspectorStuff : VBoxContainer = $HoverHoriz/InspectorParent

var hoverFocused : Texture2D = load("res://Resources/Textures/fmabcrosshairselected.png")
var hoverUnfocused : Texture2D = load("res://Resources/Textures/fmabcrosshairopen.png")


func _process(_d):
	if disabled: # alternative method of disabling
		visible = false
		return
	var camera : Camera3D = get_viewport().get_camera_3d()
	
	if !GLOBAL.in_game:
		visible = false
		return

	visible = true

	# check if disabled
	if target == Vector3.ZERO:
		self.set_position(get_viewport().get_visible_rect().size/2 - Vector2(32, 0))
		inspectorStuff.visible = false
		return
	inspectorStuff.visible = true
	self.visible = true
	
	# update texture
	if focused:
		cursor.texture = hoverFocused
	else:
		cursor.texture = hoverUnfocused
	
	var target_2d : Vector2 = camera.unproject_position(target)
	self.set_position(target_2d)
