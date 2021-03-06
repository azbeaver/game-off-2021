extends Enemy

onready var _sprite = $CreatureSprite
onready var _hitbox = $EnemyHitbox

const starting_hp = 3
const jump_impulse = -400
const walk_speed = 100
const bump_absorbance = 0
var walk_direction = 1
var _stunned = false
var _dead = false


func set_target_group(group):
	$EnemyHitbox.target_group = group


func _ready():
	hp = starting_hp
	acceleration = 0.9
	velocity.x = walk_direction * walk_speed


func _physics_process(_delta):
	# Mind controlled behavior
	if controlled:
		movement_velocity = Vector2.ZERO
		if Input.is_action_pressed("ui_left"):
			movement_velocity.x += -1 * walk_speed
		if Input.is_action_pressed("ui_right"):
			movement_velocity.x += walk_speed
		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			velocity.y = jump_impulse * Global.time_multiplier
	# Standard behavior
	else:
		if not _stunned:
			movement_velocity = Vector2(walk_direction * walk_speed, 0)


func _on_Timer_timeout():
	# Jump!
	if is_on_floor() and not _stunned and not controlled:
		velocity.y = jump_impulse * Global.time_multiplier


func _on_EnemyHitbox_hitbox_entered():
	velocity.x = sign(velocity.x) * walk_speed


func _on_TestEnemy_collided_with_wall():
	walk_direction *= -1


func _on_TestEnemy_collided_with_body(collision):
	var collision_velocity = collision.collider_velocity
	if collision_velocity.length() > bump_absorbance:
		collision_velocity = (collision_velocity.length() - bump_absorbance) * collision_velocity.normalized()
		bump(collision_velocity)


func _on_TestEnemy_stunned():
	_hitbox.monitoring = false
	_sprite.animate_stun()
	_stunned = true


func _on_TestEnemy_unstunned():
	_hitbox.monitoring = true
	_sprite.animate_unstun()
	_stunned = false
	if is_on_floor():
		velocity.y += jump_impulse


func _on_TestEnemy_killed(source):
	if not _dead:
		_dead = true
		_hitbox.set_deferred("monitoring", false)
	
		match source:
			death_source.IMPACT:
				_sprite.animate_explode()
			death_source.EXPLOSION:
				_sprite.animate_big_explode()
			death_source.ERASE:
				_sprite.animate_fade_away()
			death_source.WATER:
				_sprite.animate_disintegrate()


func _on_CreatureSprite_finished_death_animation():
	queue_free()
