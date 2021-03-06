extends KinematicBody2D

signal collided_with_body(collision)
signal collided_with_wall
signal collided_with_floor
signal collided_with_ceiling
signal damaged
signal killed

# Scene variables
onready var animation_tree = $AnimationTree
onready var _sprite = $PlayerSprite
onready var _raycast_gravity_R = $CollisionGravityRayCastR
onready var _raycast_gravity_L = $CollisionGravityRayCastL
onready var _invincibility_timer = $InvincibilityTimer
onready var _stun_timer = $StunTimer
onready var _tween = $Tween

onready var _audio_jump = $AudioJump

# Game variables
var hp = 0
const base_hp = 8
const _jump_forgiveness_time = 0.1 # Time after leaving a platform that the player can still jump
var _air_time = _jump_forgiveness_time # Time that the player is in the air
var action1_script = null
var action2_script = null
var disabled = false
var input_disabled = false
var is_outside_movement = false # Indicates that outside scripts are updating the player's velocity
var invincible = false
var _is_facing_left = false

# Physics variables
var gravity = 30
var jump_gravity = 0
var jump_gravity_acceleration = 0.94
var jump_impulse = -400 # Instantaneous velocity that is applied when the player jumps
var move_speed = 180 # X Velocity that is clamped to while the player is moving
var acceleration = 0.2 # Ratio that the X velocity is lerped to move_speed while moving with player input
var friction = 0.15 # Ratio that the X velocity is lerped to 0 while not moving with player input
var velocity = Vector2.ZERO
var is_jumping = false
var _bumping = false
var _bump_impulse = Vector2.ZERO
var _is_on_floor = false


func hide():
	_tween.interpolate_property(
		self,
		"modulate",
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.0),
		0.25,
		Tween.TRANS_QUAD,Tween.EASE_IN_OUT
	)
	_tween.start()

func show():
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func bump(impulse):
	_bumping = true
	_bump_impulse += impulse


func stun(time):
	input_disabled = true
	_sprite.animate_stun()
	
	_stun_timer.wait_time = time
	_stun_timer.start()

# NOTE/BUG:
# Damage is not applied if the user is inside a hitbox after the invincibility timer has expired!
# However, the timer is so short that this is a small issue.
func take_damage(damage, _source : int = 0):
	hp -= damage
	
	invincible = true
	_invincibility_timer.start()
	
	if hp > 0:
		animation_tree.set("parameters/OneShot 3/active", true)
		emit_signal("damaged")
	elif not input_disabled:
		animation_tree.set("parameters/death_state/current", 1)
		input_disabled = true
		emit_signal("killed")


func is_facing_left():
	return _is_facing_left

func is_on_floor():
	return _is_on_floor

func reset():
	animation_tree.set("parameters/death_state/current", 0)


func _ready():
	animation_tree.active = true
	_is_on_floor = _raycast_gravity_L.is_colliding()
	if _is_on_floor:
		_air_time = 0


# TODO:
# Handle directional input and weapon additional input at the same time
# Current solution is disabling input
func _physics_process(delta):
	if disabled:
		return
	
	# -------------------
	# | INPUT DETECTING |
	# -------------------
	var direction = 0
	if not input_disabled:
		# Detect action input
		if Input.is_action_just_pressed("ui_accept") and action1_script != null:
			action1_script.trigger()
		if Input.is_action_just_pressed("ui_select") and action2_script != null:
			action2_script.trigger()
		
		# Detect horizontal input
		if Input.is_action_pressed("ui_left"):
			direction += -1
		if Input.is_action_pressed("ui_right"):
			direction += 1
		
		# Detect vertical input
		if Input.is_action_just_pressed("ui_up") and _air_time < _jump_forgiveness_time:
			velocity.y = jump_impulse
			_is_on_floor = false
			is_jumping = true
			jump_gravity = 0
			
			_audio_jump.pitch_scale = rand_range(0.7, 0.9)
			_audio_jump.play()
	
	
	if (Input.is_action_just_released("ui_up") or velocity.y > 0 or input_disabled) and is_jumping:
		is_jumping = false
	
	# -------------------------------
	# | CREATE MOVEMENT AND ANIMATE |
	# -------------------------------
	
	# Interpolate based on horizontal input
	if not is_outside_movement:
		if direction != 0:
			velocity.x = lerp(direction * move_speed, velocity.x, acceleration)
			
			if direction == 1:
				_sprite.scale.x = 1
				_is_facing_left = false
			else:
				_sprite.scale.x = -1
				_is_facing_left = true
			
			if _is_on_floor:
				animation_tree.set("parameters/in_air_state/current", 0)
				animation_tree.set("parameters/movement/current", 1)
			
		else:
			velocity.x = lerp(velocity.x, 0, friction)
			
			if _is_on_floor:
				animation_tree.set("parameters/in_air_state/current", 0)
				animation_tree.set("parameters/movement/current", 0)

	
	# Add gravity
	if is_jumping:
		jump_gravity = lerp(gravity, jump_gravity, jump_gravity_acceleration)
		velocity.y += jump_gravity
	else:
		velocity.y += gravity
	
	# Animate fall
	if not _is_on_floor:
		animation_tree.set("parameters/in_air_state/current", 1)
		if velocity.y > 0:
			animation_tree.set("parameters/in_air/current", 0)
		else:
			animation_tree.set("parameters/in_air/current", 1)
	
	# Apply bump impulse
	if _bumping:
		velocity.x = _bump_impulse.x
		velocity.y = _bump_impulse.y
		_bumping = false
		_is_on_floor = _bump_impulse.y < 0
		_bump_impulse = Vector2.ZERO
	
	# ------------------
	# | APPLY MOVEMENT |
	# ------------------
	
	var collision = move_and_collide(delta * velocity, true, true, true)
	
	# Check for colliding with body
	if collision != null and not collision.collider is TileMap:
		emit_signal("collided_with_body", collision)
	
	# Move the player based on velocity
	velocity = move_and_slide(velocity, Vector2(0, -1))
	
	# Manage in-air variables
	if  _raycast_gravity_L.is_colliding() or _raycast_gravity_R.is_colliding():
		animation_tree.set("parameters/in_air_state/current", 0)
		_air_time = 0
	else:
		_air_time += delta
	_is_on_floor = _air_time < _jump_forgiveness_time
	
	# Emit collision signals when applied
	if is_on_wall():
		emit_signal("collided_with_wall")
	if is_on_floor():
		emit_signal("collided_with_floor")
	if is_on_ceiling():
		emit_signal("collided_with_ceiling")


func _on_InvincibilityTimer_timeout():
	invincible = false


func _on_StunTimer_timeout():
	input_disabled = false
	_sprite.animate_unstun()
