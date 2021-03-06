extends Area2D

onready var _impact_particles = $ImpactParticles

onready var _audio = $Audio

var stomp_damage = 0
var stomp_enemy_impulse = Vector2(0, 30)
var stun_time = 6
var _player = null


func equip(player):
	_player = player
	_player.add_child(self)
func unequip():
	_player.remove_child(self)
	_player = null


func _on_Area2D_body_entered(body):
	if body.is_in_group("enemy") and _player.velocity.y > 0:
		_player.velocity.y *= -1
		body.bump(stomp_enemy_impulse)
		body.take_damage(stomp_damage)
		body.stun(stun_time)
		_impact_particles.restart()
		
		_audio.pitch_scale = rand_range(0.8, 1.1)
		_audio.play()
