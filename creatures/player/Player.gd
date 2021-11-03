extends KinematicBody2D

signal collided_x
signal collided_y

# Scene variables
onready var _sprite = $CreatureSprite
onready var _invincibility_timer = $InvincibilityTimer

# Game variables
var hp = 0
var action1_script = null
var action2_script = null
var input_disabled = false

# Physics variables
const _gravity = 30 # px / sec^2
const _jump_impulse = -640 # px / sec 
const _wall_bounce_impulse = 20
const _move_speed = 240 # px / sec
const _friction = 0.15
const _acceleration = 0.2
var velocity = Vector2.ZERO
var invincible = false
var _is_on_floor = false
var _taking_damage = false
var _damage_impulse = Vector2.ZERO

# NOTE/BUG:
# Damage is not applied if the user is inside a hitbox after the invincibility timer has expired!
# However, the timer is so short that this is a small issue.
func take_damage(damage, impulse):
	if not invincible:
		hp -= damage
		_taking_damage = true
		_damage_impulse = impulse
		
		invincible = true
		_invincibility_timer.start()


func is_facing_left():
	return _sprite.scale.x == -1

func is_on_floor():
	return _is_on_floor


func _ready():
	_sprite.play()


# TODO:
# Handle directional input and weapon additional input at the same time
func _physics_process(delta):
	# Detect horizontal input
	var direction = 0
	if Input.is_action_pressed("ui_left") and not _taking_damage and not input_disabled:
		direction += -1
	if Input.is_action_pressed("ui_right") and not _taking_damage and not input_disabled:
		direction += 1
	
	# Interpolate based on horizontal input
	if direction != 0:
		velocity.x = lerp(direction * _move_speed, velocity.x, _acceleration)
		
		if direction == 1:
			_sprite.flip_h(false)
		else:
			_sprite.flip_h(true)
		
		if _is_on_floor:
			_sprite.animation = "run"
	else:
		velocity.x = lerp(velocity.x, 0, _friction)
		
		if _is_on_floor:
			_sprite.animation = "default"
	
	# Add gravity
	velocity.y += _gravity
	
	# Animate fall
	if not _is_on_floor and velocity.y > 0:
		_sprite.animation = "fall"
	
	# Apply damage impulse
	if _taking_damage:
		velocity.x += _damage_impulse.x
		velocity.y = _damage_impulse.y
		_taking_damage = false
		_is_on_floor = false
	
	# Checks for x collisions
	var collision_x = move_and_collide(delta * Vector2(velocity.x, -0.1), true, true, true)
	
	# Move the player based on velocity
	velocity = move_and_slide(velocity, Vector2(0, -1))
	
	# Emit collision signals if applies
	if collision_x != null:
		var sign_x = sign(collision_x.normal.x)
		if sign_x == 0:
			sign_x = 1
		velocity += _wall_bounce_impulse * Vector2(sign_x, -0.1)
		emit_signal("collided_x")
	
	# Sets _is_on_floor to true if on floor in the NEXT frame
	# Allows for handling of jump input the same frame that the player lands
	if not _is_on_floor and test_move(transform, delta * (velocity + Vector2(0, _gravity))):
		_is_on_floor = true
		emit_signal("collided_y")
	
	# Detect vertical input
	if _is_on_floor and Input.is_action_just_pressed("ui_up") and not input_disabled:
		velocity.y = _jump_impulse
		_is_on_floor = false
		
		# Animate jump
		_sprite.animation = "jump"
	
	# Detect action input
	if Input.is_action_just_pressed("ui_accept") and action1_script != null and not input_disabled:
		action1_script.trigger()


func _on_InvincibilityTimer_timeout():
	invincible = false
