extends Area2D
 
onready var _animation_player = $AnimationPlayer

export var lunge_velocity := Vector2.ZERO
export var is_decelerating := false
export var is_lunging := false
var lunge_damage = 0
var lunge_impact_impulse = 100
var _can_lunge = true
var _player = null
var _player_facing_left = false
var _player_gravity = 0


func equip(player):
	_player = player
	_player.add_child(self)
	_player.connect("collided_x", self, "_on_impact_x")
	_player.connect("collided_y", self, "_on_impact_y")


func trigger():
	if _can_lunge:
		_can_lunge = false
		
		lunge_velocity = Vector2(600, 0)
		monitoring = true
		
		_animation_player.play("lunge")
		
		# Determine velocity
		if _player.is_facing_left():
			_player_facing_left = true
			scale.x = -1
		
		# Disable player input
		_player.invincible = true
		_player.input_disabled = true
		_player.is_outside_movement = true
		
		# Update player velocity
		_player.velocity.x = lunge_velocity.x * (-1 if _player_facing_left else 1)
		_player.velocity.y = lunge_velocity.y
		
		# Update player gravity
		_player_gravity = _player.gravity
		_player.gravity = 0
	else:
		_player.input_disabled = false


func _physics_process(_delta):
	if is_lunging or is_decelerating:
		_player.velocity.x = lunge_velocity.x * (-1 if _player_facing_left else 1)


func _set_lunge_velocity(velocity: Vector2):
	lunge_velocity = velocity


func _stop_lunging():
	is_lunging = false
	is_decelerating = true
	_player.gravity = _player_gravity
	_player.invincible = false
	_player.input_disabled = false
	_player.is_outside_movement = false
	monitoring = false


func _stop_decelerating():
	is_decelerating = false
	_player_facing_left = false
	scale.x = 1
	_can_lunge = true


func _on_impact_x():
	print("Impact x")
	if is_lunging:
		_stop_lunging()
		_stop_decelerating()
		_animation_player.stop(true)
	elif is_decelerating:
		_stop_decelerating()
		_animation_player.stop(true)


func _on_impact_y():
	if not _can_lunge:
		_can_lunge = true


func _on_Area2D_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(
			lunge_damage,
			lunge_impact_impulse * (body.global_position - global_position + Vector2(0, -0.1)).normalized(),
			0.05
		)
