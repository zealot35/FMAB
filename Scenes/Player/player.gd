extends CharacterBody3D

#region Mouse vars
var mouselock := true
var mouse_sensitivity : float = 0.3
#endregion
#region Speed vars
@export var crouch_speed : float = 3
@export var walk_speed : float = 5
@export var sprint_speed : float = 8
var air_speed : float = 150

var cur_speed : float = walk_speed
#endregion

#region Crouch stuff
## the height the camera will be below the current body height.
@export var head_below_height : float = 0.1
@export var standing_height : float = 1.8
@export var crouching_height : float = 1.0

var crouched : bool = false
#endregion

#region Stair stuff
var max_step_height : float = 0.53
var step_head_bounce_time : float = 0.35
var stepping_allowed : bool = false
## velocity gets set to this after each step
var pre_step_velocity : Vector3
## the current position of the head this frame
var pre_step_head_pos : Vector3
## the head position we want to return to
var wish_head_pos : Vector3
## the time the head has moved, up to the step_head_bounce_time
var head_travel_amount : float = 0.0
## ensures head gets put back to proper state
var head_just_stair_lerped : bool = false
#endregion

#region Debug stuff
var noclipping : bool = false
var noclip_speed : float = 5.0
var noclip_sprint : float = 15.0
#endregion

#region Input stuff
var is_jumping : bool = false
var is_running : bool = false
var is_ducking : bool = false
var is_walking : bool = false

var input_dir := Vector2.ZERO
var next_footstep : float = 0.5
var sprint_footstep : float = 0.3
var footstep_amt : float = 0.0

#region Gravity vars
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity_y : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity : Vector3 = Vector3(0, gravity_y, 0)
@export var jump_vel : float = 4.5
#endregion
#region Friction vars

#On ground, accel is how quickly you can switch from one direction to the exact opposite direction. Gives a bit of nice delay.
@export var accel : float = 8

#Accel is above zero since airstrafe is contingent on letting the player *gain* momentum, but it's kept small so it's not jank. 
@export var air_accel : float = 1

#Holder vars for deciding what the current values should be.
var cur_accel : float = accel

var air_cap := 0.75
var max_vel = 2.5 # m/ per frame

#Friction vars - Rate at which you lose speed?
var s_friction := 5.0 # s for shit
var friction_strength : float = 1.0

#endregion
#region Velocity vars
var direction : Vector3 = Vector3()
var leftright_dir : float = 0.0
var target_vel : Vector3 = Vector3()
var proj_vel : float = 0
#endregion

#region States
enum STATES {GROUND, NOCLIP}
var move_state : int = STATES.GROUND
#endregion

#region Nodes
@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera
@onready var camFollowTarget : RayCast3D = $Head/CamFollowTarget
@onready var camFollowWheel : RayCast3D = $Head/CamFollowWheel
@onready var eyeTrace : RayCast3D = $Head/Camera/EyeTrace
@onready var colBody : CollisionShape3D = $StandCol
@onready var colCrouch : CollisionShape3D = $CrouchCol
@onready var crouchCheck : ShapeCast3D = $CrouchCheck
@onready var stepShapeCheck : ShapeCast3D = $StepCheck
@onready var stepRayCheck : RayCast3D = $StepRayCheck
@onready var footstep : AudioStreamPlayer3D = $Head/Footsteps

@onready var footsteps : Array = [
	load("res://Resources/Sounds/sfx100v2_footstep_wood_01.ogg"),
	load("res://Resources/Sounds/sfx100v2_footstep_wood_02.ogg"),
	load("res://Resources/Sounds/sfx100v2_footstep_wood_03.ogg"),
	load("res://Resources/Sounds/sfx100v2_footstep_wood_04.ogg"),
]

#endregion

#region Interaction vars
var holding_something : bool = false

var throw_force : float = 7.5
var min_throw_force : float = 3.0
var max_throw_force : float = 15.0
var follow_speed : float = 5.0
var follow_distance : float = 2.5
var max_distance : float = 0.5
var max_pickup_weight : float = 0.25
var drop_below_player : bool = false

var rotation_diff : Quaternion
var dist : float = 1.2

var pickup_time_wait : int = 0
var pickup_time_min : int = 200

var punt_object : bool = false

const ROTATION_TOLERANCE : float = 0.8
const ARC_RESOLUTION : float = 12.0
const ROTATION_SENSITIVITY : float = 0.0025
const GRAB_MAX : float = 4.0
const GRAB_MIN : float = 0.5

var held_object : RigidBody3D

var hovering_collider
#endregion

#region Inspection stuff
@export var inspector_alpha_reset_time : float = 0.75
@export var inspector_alpha_lerp_time : float = 0.1
var last_mouse_move : int = 0
var current_mouse_vel : Vector2 = Vector2()
var inspector_alpha_lerp_amount : float = 0.0
var current_inspector_alpha : float = 1.0
var min_inspector_alpha : float = 0.25
var inspector_alpha_is_minimized : bool = false
#endregion

#region Game mechanic stuff
@export var health : int = 100
@export var max_health : int = 100
@export var is_active : bool = false
var is_dead : bool = false

# for debugging current physics frame time
var arr_phys_time : Array = []
var acc_phys_time : int = 0

var debugUI : Label

func _ready():
	footstep.stream = AudioStreamPolyphonic.new()
	footstep.unit_size = 1.5
	footstep.pitch_scale = randf_range(0.9,1.1)
	footstep.play()
	debugUI = GLOBAL.debugUI
	GLOBAL.player = self


func resetPlayer():
	health = max_health
	is_dead = false
	position = Vector3.ZERO
	velocity = Vector3.ZERO
	toggleMouselock(true)


func playerDeath():
	physicsGrabbing(true)
	pass


func beginGame():
	is_active = true
	camera.current = true
	toggleMouselock(true)


func _physics_process(delta):
	if !is_active:
		return
	if arr_phys_time.size() > 120:
		for i in arr_phys_time:
			acc_phys_time += i
		acc_phys_time /= arr_phys_time.size()
		print("accumulated physics time: ", float(acc_phys_time)/1000000.0, " seconds")
		arr_phys_time.clear()
	
	var vsync_text : String
	var switch_vsync : int = (DisplayServer.VSYNC_ENABLED if 
		DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED else
		DisplayServer.VSYNC_DISABLED)
	if switch_vsync != DisplayServer.VSYNC_ENABLED:
		vsync_text = "ON"
	else:
		vsync_text = "OFF"
	if GLOBAL.debug_mode:
		debugUI.text = ""
		debugUI.text += "accumulated physics time: " + str(float(acc_phys_time)/1000000.0) + " seconds\n"
		debugUI.text += "current speed: " + str(snappedf(velocity.length(), 0.01)) + " m/s\n"
		debugUI.text += "fps: " + str(Engine.get_frames_per_second()) + "\n"
		debugUI.text += "move: WASD\n"
		debugUI.text += "jump: space\n"
		debugUI.text += "toggle vsync: end (" + vsync_text + ")\n" 
	
	if Input.is_action_just_pressed("ui_end"):
		DisplayServer.window_set_vsync_mode(switch_vsync)
	
	var _time_start : int = Time.get_ticks_usec()
	getInput(delta)
	holding_something = held_object != null
	modifyInspectorAlpha(delta)

	if move_state == STATES.GROUND:
		proj_vel = direction.normalized().dot(target_vel.normalized())
		if crouched:
			cur_speed = crouch_speed
		elif is_running:
			cur_speed = sprint_speed
		else:
			cur_speed = walk_speed
		target_vel = direction * cur_speed
		moveGround(delta)
		checkCrouch(delta)
		checkStep(delta)
	elif move_state == STATES.NOCLIP:
		doNoclip(delta)
	
	holdingObject(delta)
	
	velocity = get_real_velocity()
	
	var _time_end : int = Time.get_ticks_usec() - _time_start
	arr_phys_time.push_back(_time_end)


func doFootstepStuff(delta):
	var playback : AudioStreamPlaybackPolyphonic = footstep.get_stream_playback()
	if direction.length() > 0.0:
		footstep_amt += delta
	else:
		footstep_amt = 0.0

	var footstep_check : float = sprint_footstep if is_running else next_footstep

	if footstep_amt >= footstep_check:
		playback.play_stream(footsteps[randi() % footsteps.size()], 0, 0, randf_range(0.9,1.1))
		footstep_amt = 0.0
	pass


func modifyInspectorAlpha(delta : float):
	if !holding_something:
		GLOBAL.set_inspector_alpha()
		return
	var vel_thing : bool = true if direction.length() > 0.0 else last_mouse_move + 10 > Time.get_ticks_msec()
	if vel_thing:
		inspector_alpha_is_minimized = true
		inspector_alpha_lerp_amount = 0.0
	else:
		inspector_alpha_lerp_amount += delta
		if inspector_alpha_lerp_amount >= inspector_alpha_reset_time: # reset alpha to 0, inspector alpha false
			inspector_alpha_is_minimized = false

	if inspector_alpha_is_minimized:
		current_inspector_alpha = lerpf(current_inspector_alpha, min_inspector_alpha, inspector_alpha_lerp_time)
	else:
		current_inspector_alpha = lerpf(current_inspector_alpha, 1.0, inspector_alpha_lerp_time)

	GLOBAL.set_inspector_alpha(current_inspector_alpha)


func checkCrouch(delta : float):
	var to_height : float
	var move_col_mag : float
	var from_height : float
	if is_ducking:
		crouched = true
		to_height = crouching_height - head_below_height
		from_height = standing_height - head_below_height
	else: # neither proning or ducking
		if crouched:
			crouchCheck.force_shapecast_update()
			if crouchCheck.is_colliding(): # wait for crouch check before uncrouching
				return
		crouched = false
		# if currently not crouching, dont worry bout it bruh
		to_height = standing_height - head_below_height
		from_height = crouching_height - head_below_height
	
	# -0.6 when uncrouch/unprone, 0.6 when crouch, should be like 0.9 or smth when proning
	move_col_mag = from_height - to_height
	

	# check if on ground
	if is_on_floor() && !head_just_stair_lerped:
		# if is in ground, do lerp thing
		# when we are prone, we use the proneHead position for our head movement
		# and we also use the pronebody basis.z to restrict our head/cam look movement
		var forward_head_vec : Vector3 = Vector3(0.0, to_height, 0.0)
		forward_head_vec.y = to_height
		forward_head_vec = Vector3(0.0, to_height, 0.0)
		head.position = (head.position.move_toward(forward_head_vec, delta*5.0)
		if !head.position.is_equal_approx(Vector3(0.0, to_height, 0.0)) else Vector3(0.0, to_height, 0.0))
	elif !is_on_floor() && is_equal_approx(head.position.y, from_height):
		move_and_collide(Vector3(0.0, move_col_mag, 0.0))
		head.position.y = to_height
	
	if is_equal_approx(head.position.y, to_height):
		head.position.y = to_height
	
	colBody.disabled = crouched
	colCrouch.disabled = !crouched

# TODO: change standing_height instances to variable current_height based on crouch/prone state.
func checkStep(delta : float):
	if !stepping_allowed:
		return
	
	var slides : int = get_slide_collision_count()
	var _collision : KinematicCollision3D
	var slide_direction : Vector3
	var just_stepped : bool = false

	if slides == 1 && !is_zero_approx(get_slide_collision(0).get_normal().y):
		return
	
	for i in slides:
		if just_stepped:
			continue
		_collision = get_slide_collision(i)
		var _slide_collider = _collision.get_collider()
		if (_slide_collider is RigidBody3D || 
		_slide_collider is CharacterBody3D):
			continue
		
		slide_direction = _collision.get_normal()
		# mostly flat wall
		if slide_direction.y > 0.02 || slide_direction.y < -0.02:
			continue
		
		var stair_pos : Vector3 = to_local(_collision.get_position())
		var new_pos : Vector3 = _collision.get_remainder()
		var cur_height : float = crouching_height if is_ducking else standing_height
		stair_pos.y = cur_height
		stepRayCheck.position = stair_pos + Vector3(0, 0.01, 0) + new_pos
		stepRayCheck.target_position.y = -cur_height
		stepRayCheck.force_raycast_update()
		if !stepRayCheck.is_colliding():
			continue
		
		var floor_pos : Vector3 = to_local(stepRayCheck.get_collision_point())
		var floor_normal : Vector3 = stepRayCheck.get_collision_normal()
		if floor_pos.y >= max_step_height:
			continue
		if floor_normal.y <= 0.8:
			continue
		
		new_pos.y = floor_pos.y
		stepRayCheck.position = floor_pos
		stepRayCheck.target_position.y = cur_height
		stepRayCheck.force_raycast_update()

		var _test_position : Vector3 = new_pos + Vector3(0, (cur_height/2.0) + 0.01, 0)
		if crouched:
			stepShapeCheck.shape = colCrouch.shape
		else:
			stepShapeCheck.shape = colBody.shape
		stepShapeCheck.position = _test_position
		stepShapeCheck.force_shapecast_update()
		# we are obstructed from walking up these stairs. zamn
		if stepShapeCheck.is_colliding() || stepRayCheck.is_colliding():
			continue
		pre_step_head_pos = head.global_position
		head_travel_amount = 0.0
		position += new_pos
		velocity = pre_step_velocity
		head.position = to_local(pre_step_head_pos)
		just_stepped = true
		# once we are at this point, we won't be doing any more stair stepping
		

		
		
	pass


func doNoclip(delta : float):
	velocity = direction * noclip_sprint if is_running else direction * noclip_speed
	move_and_slide()


func moveGround(delta : float, _vel : Vector3 = velocity, _dir : Vector3 = direction):
	if is_on_floor():
		if is_jumping:
			velocity.y = jump_vel
			stepping_allowed = false
		else:
			doFootstepStuff(delta)
			applyFriction(delta, friction_strength)
			applyAccel(delta, direction, target_vel.length(), accel)
			stepping_allowed = true
				# move tanktestbody and align view to it
	else:
		stepping_allowed = false
		velocity -= gravity * delta * 1.5
		applyAirAccel(delta, direction, target_vel.length(), air_accel)
	
	pre_step_velocity = velocity
	move_and_slide()


func applyAccel(delta: float, wish_dir: Vector3, wish_vel: float, f_accel: float):
	var add_vel : float
	var accel_vel : float
	proj_vel = 0.0
	
	# See if we are changing direction a bit
	proj_vel = velocity.dot(wish_dir)
	
	# Reduce wishspeed by the amount of veer.
	add_vel = wish_vel - proj_vel
	
	# If not going to add any speed, done.
	if add_vel <= 0:
		return;
		
	# Determine the amount of acceleration.
	accel_vel = f_accel * wish_vel * delta
	
	# Cap at addspeed
	if accel_vel > add_vel:
		accel_vel = add_vel
	
	# Adjust velocity.
	velocity += accel_vel * wish_dir


func applyAirAccel(delta: float, wish_dir: Vector3, wish_vel: float, f_accel: float):
	var add_vel : float
	var accel_vel : float
	proj_vel = 0.0
	var air_vel : float = wish_vel
	
	if (air_vel > air_cap):
		air_vel = air_cap
	
	# See if we are changing direction a bit
	proj_vel = velocity.dot(wish_dir)
	
	# Reduce wishspeed by the amount of veer.
	add_vel = air_vel - proj_vel
	
	# If not going to add any speed, done.
	if add_vel <= 0:
		return;
		
	# Determine the amount of acceleration.
	accel_vel = f_accel * wish_vel * delta
	
	# Cap at addspeed
	if accel_vel > add_vel:
		accel_vel = add_vel
	
	# Adjust velocity.
	velocity += accel_vel * wish_dir


func applyFriction(delta: float, strength: float):
	var cur_vel = velocity.length()
	
	# Bleed off some speed, but if we have less that the bleed
	# threshold, bleed the threshold amount.
	var control = max_vel if (cur_vel < max_vel) else cur_vel
	
	# Add the amount to the drop amount
	var drop = control * delta * s_friction * strength
	
	# Scale the velocity.
	var new_vel = cur_vel - drop
	
	if new_vel < 0: new_vel = 0
	if cur_vel > 0: new_vel /= cur_vel
	
	velocity.x *= new_vel
	velocity.z *= new_vel


func holdingObject(delta):
	if held_object == null:
		return
	
	var _f := camera.get_camera_transform().basis.x
	var _r := camera.get_camera_transform().basis.z
	var _u := camera.get_camera_transform().basis.y

	var rel_to_cam_rotation : Quaternion = Quaternion(camera.get_camera_transform().basis) * rotation_diff
	if held_object.is_in_group("is_wheel"):
		rel_to_cam_rotation = Quaternion(camFollowWheel.basis) * rotation_diff

	var desired_rot : Quaternion = rel_to_cam_rotation

	rotation_diff = Quaternion(camera.get_camera_transform().basis).inverse() * desired_rot
	if held_object.is_in_group("is_wheel"):
		rotation_diff = Quaternion(camFollowWheel.basis).inverse() * desired_rot

	var from : Vector3 = camFollowTarget.global_position
	# normal used to calculate object hold position
	var _pos : Vector3 = -camFollowTarget.global_basis.z
	
	if held_object.is_in_group("is_wheel"):
		if camFollowTarget.is_colliding():
			_pos = -(to_local(camFollowTarget.get_collision_point()))
	
	var cust_dist : float = dist

	if held_object.is_in_group("grab_me_boy"):
		cust_dist = camera.global_position.distance_to(held_object.global_position)

	# where the object will be held
	var hold_point : Vector3 = from + (_pos * cust_dist)
	# if held_object.is_in_group("grab_me_boy"):
	# 	hold_point = from + _pos
	# need to get 'center point' for held_object
	var prop = held_object.get_parent()
	var origin : Vector3 = held_object.global_transform.origin
	if (prop is PropBase):
		if prop.get("hoverTarget"):
			origin = prop.hoverTarget()
	var to_dest : Vector3 = hold_point - origin
	# center_dest - held_object.global_transform.origin
	var force : Vector3 = (to_dest / (delta * (0.8 * held_object.mass)))
	# print("distance to middle: ", held_object.global_position.distance_to(hold_point))
	if held_object.global_position.distance_to(hold_point) > 2.0:
		held_object.remove_collision_exception_with(self)
		camFollowTarget.remove_exception(held_object)
		held_object = null
		return

	# held_object.linear_velocity = Vector3.ZERO
	# held_object.angular_velocity = Vector3.ZERO

	var rot_diff : Quaternion = desired_rot * Quaternion(held_object.global_basis.orthonormalized()).inverse()

	# test object to see if it can move where we want it to go
	var kin_col : KinematicCollision3D = KinematicCollision3D.new()
	var res : bool = held_object.test_move(held_object.global_transform, force * delta, kin_col, 0.005, false, 4)

	# need to slide object along normal if we are trying to push it into a wall or smth
	if res:
		var total_force : Vector3 = force
		for i in kin_col.get_collision_count():
			total_force = total_force.slide(kin_col.get_normal(i))
		force = total_force
	
	held_object.linear_velocity = force

	held_object.angular_velocity = rot_diff.get_euler() * 0.5 / (delta * (0.8 * held_object.mass))

	# dist = (from - hold_point).length()
	pass


func interact():
	if mouselock:
		if !doInteract():
			physicsGrabbing(true)


func primary():
	if mouselock:
		physicsPunting()
	
	pass


func secondary():
	if mouselock:
		physicsGrabbing()


func removeRelationWithProp(phys):
	phys.remove_collision_exception_with(self)
	camFollowTarget.remove_exception(phys)
	pickup_time_wait = Time.get_ticks_msec() + pickup_time_min
	held_object = null # we are assuming that this is the held item
	# do not assume we are dealing with a prop... please.... please be a prop
	if !(phys.get_parent() is PropBase):
		return
	phys.get_parent().togglePropActivity(false)
	pass


func doInteract() -> bool:
	if !eyeTrace.is_colliding():
		return false
	
	var col = eyeTrace.get_collider()

	var is_prop : bool = col.get_parent() is PropBase
	
	var interactor

	if is_prop:
		interactor = col.get_parent() as PropBase
	
	if interactor == null:
		return false

	if !interactor.has_method(&"interact"):
		return false
	
	# if res is null then result will be true
	var res = interactor.interact()

	return res if res != null else true


func physicsPunting():
	if pickup_time_wait > Time.get_ticks_msec():
		return

	var throw_dir : Vector3

	if held_object == null:
		# perform temporary punt if eyetrace
		if !eyeTrace.is_colliding():
			return
		
		if !(eyeTrace.get_collider() is RigidBody3D):
			return
		
		var col : RigidBody3D = eyeTrace.get_collider()

		if col.freeze:
			return
		
		# local_hit_diff = held_object.to_local($follower.position)

		throw_dir = eyeTrace.global_basis.z * clamp(throw_force / (col.mass / 2.0), min_throw_force, max_throw_force)

		# held_object.linear_velocity = Vector3.ZERO
		# held_object.angular_velocity = Vector3.ZERO

		col.linear_velocity += throw_dir
		
		pickup_time_wait = Time.get_ticks_msec() + int(pickup_time_min + (col.mass * 5.0))
		return
	else:
		held_object.remove_collision_exception_with(self)
		camFollowTarget.remove_exception(held_object)

	pickup_time_wait = Time.get_ticks_msec() + (pickup_time_min + int(held_object.mass * 5.0))
	
	throw_dir = camera.project_ray_normal(get_viewport().get_visible_rect().size / 2.0) * clamp(throw_force / (held_object.mass / 2), min_throw_force, max_throw_force)
	held_object.linear_velocity += throw_dir

	held_object = null


func physicsGrabbing(drop : bool = false):
	if !drop:
		drop = held_object != null
	if drop:
		if held_object == null:
			return
		
		tryDroppingPhysObject(held_object)
		pickup_time_wait = Time.get_ticks_msec() + pickup_time_min
		held_object = null
		return

	if pickup_time_wait > Time.get_ticks_msec():
		return

	if !eyeTrace.is_colliding():
		return
	
	if !(eyeTrace.get_collider() is RigidBody3D):
		return
	
	var col : RigidBody3D = eyeTrace.get_collider()
	
	if col.freeze:
		return

	var prop = col.get_parent()

	if !(prop is PropBase):
		return
	
	if !prop.isGrabbable():
		return
	
	var col_point := eyeTrace.get_collision_point()

	held_object = col
	held_object.add_collision_exception_with(self)
	camFollowTarget.add_exception(col)
	rotation_diff = Quaternion(camera.get_camera_transform().basis).inverse() * Quaternion(held_object.global_transform.basis.orthonormalized())
	pass


func tryDroppingPhysObject(dropping_object):
	if !(dropping_object is PhysicsBody3D):
		return
	# check to makes sure we are not intersecting the collision object
	dropping_object.remove_collision_exception_with(self)
	camFollowTarget.remove_exception(dropping_object)
	var prop = dropping_object.get_parent()

	# how tf did we get here?
	if !(prop is PropBase):
		return
	
	# var kin : KinematicCollision3D = KinematicCollision3D.new()
	# var res : bool = dropping_object.test_move(dropping_object.global_transform, Vector3.ZERO, kin, 0.005, false, 4)

	# var player_is_intersecting : bool = false

	# if res:
	# 	dropping_object = dropping_object as RigidBody3D
	# 	for i in kin.get_collision_count():
	# 		if kin.get_collider(i) == self:
	# 			player_is_intersecting = true
	# 			break

	# if player_is_intersecting:
	# 	dropping_object.set_collision_layer_value(1, false)

	# prop._intersecting_player = player_is_intersecting


func doEyeTrace():
	eyeTrace.target_position = Vector3(0, 0, -3.0)

func doInspect():
	GLOBAL.inspectorName.visible = false
	GLOBAL.inspectorDesc.visible = false
	var prop = null
	var no_hover_update : bool = false
	# print(held_object)
	if held_object != null: # hover on held object
		no_hover_update = true
		prop = held_object.get_parent() if held_object != null else null
		if prop == null:
			return
		# every collider should have the propbase as a parent
		if !(prop is PropBase) or !(prop.selectable):
			GLOBAL.hover.target = held_object.global_position
		else:
			GLOBAL.hover.target = prop.hoverTarget() if prop.get("hoverTarget") else prop.global_position
		GLOBAL.hover.focused = true
	
	if !eyeTrace.is_colliding():
		if !no_hover_update:
			GLOBAL.hover.target = Vector3.ZERO
		return
	
	if eyeTrace.get_collider() != null:
		prop = eyeTrace.get_collider().get_parent() if prop == null else prop
	# every collider should have the propbase as a parent
	if !(prop is PropBase) or !(prop.selectable):
		if !no_hover_update:
			GLOBAL.hover.target = Vector3.ZERO
		return

	if (!no_hover_update):
		GLOBAL.hover.target = prop.hoverTarget() if prop.get("hoverTarget") else prop.global_position
		GLOBAL.hover.focused = (held_object != null)

	GLOBAL.inspectorName.visible = true
	GLOBAL.inspectorDesc.visible = true

	GLOBAL.inspectorName.text = prop.prop_name 
	GLOBAL.inspectorDesc.text = prop.prop_desc 


func toggleMouselock(toggle : bool = false):
	mouselock = toggle
	if mouselock: 
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GLOBAL.mainMenu.visible = false
	else: 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GLOBAL.mainMenu.visible = true




func getInput(_delta):
	input_dir = Vector2.ZERO
	direction = Vector3.ZERO
	is_jumping = false
	is_running = false
	is_ducking = false
	is_walking = false
	mouse_sensitivity = PlayerConfig.get_config(AppSettings.INPUT_SECTION, "MouseSensitivity", 0.3)
	
	if !mouselock:
		return

	doEyeTrace()

	doInspect()
	
	is_jumping = Input.is_action_pressed("jump")
	is_running = Input.is_action_pressed("sprint")
	if Input.is_action_pressed("crouch"):
		is_ducking = true
		
	if Input.is_action_just_pressed("noclip"):
		if !GLOBAL.debug_mode:
			return
		print("noclip: ", noclipping)
		if !noclipping:
			move_state = STATES.NOCLIP
			colBody.disabled = true
			colCrouch.disabled = true
			noclipping = true
		elif noclipping:
			move_state = STATES.GROUND
			noclipping = false
			if crouched:
				colCrouch.disabled = false
			else:
				colBody.disabled = false

	if Input.is_action_just_pressed("interact"):
		interact()

	if Input.is_action_just_pressed("secondary"):
		secondary()
	
	if Input.is_action_just_pressed("primary"):
		primary()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if noclipping:
		direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if is_jumping:
			direction.y += 1.0
		if is_ducking:
			direction.y -= 1.0
	else:
		direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	

	
func _process(delta):
	if !is_active:
		return
	# camera lerp for stairstepping
	if head_travel_amount <= step_head_bounce_time:
		head_travel_amount += delta
		wish_head_pos = Vector3()
		wish_head_pos.y = (crouching_height if crouched else standing_height) - head_below_height
		head.position = head.position.move_toward(wish_head_pos, delta * 3)
		head_just_stair_lerped = true
	elif head_travel_amount >= step_head_bounce_time && head_just_stair_lerped:
		head.position = wish_head_pos
		head_just_stair_lerped = false
	

func _input(event):
	if !is_active:
		return
	#Mouse capture debug
	if Input.is_action_just_pressed("pause"):
		toggleMouselock(!mouselock)
	
	#Camera movement
	if mouselock:
		if event is InputEventMouseMotion:
			last_mouse_move = Time.get_ticks_msec()
			head.rotation.y += deg_to_rad(-event.relative.x * mouse_sensitivity)
			camera.rotation.x += deg_to_rad(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			camFollowTarget.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(45))
			camFollowWheel.rotation.x = clamp(-camera.rotation.x, deg_to_rad(-45), deg_to_rad(45))
			camFollowTarget.position.z = camera.position.z
			# camFollowTarget.rotation.x = clamp(camFollowTarget.rotation.x, deg_to_rad(-60), deg_to_rad(60))
