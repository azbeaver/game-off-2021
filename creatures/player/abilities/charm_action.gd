extends Area2D

onready var _timer = $Timer

var charm_time = 4
var recharge_time = 4
var _player = null
var _can_charm = true
var _is_recharging = false
var _charmed_bodies = []


func equip(player):
	_player = player
	_player.add_child(self)
func unequip():
	_player.remove_child(self)
	_player = null


func trigger():
	if _can_charm:
		var facing_left = _player.is_facing_left()
		
		for body in get_overlapping_bodies():
			if body.is_in_group("enemy") and body.has_method("set_target_group"):
				if ((facing_left and body.global_position.x < global_position.x)
					or (not facing_left and body.global_position.x > global_position.x)):
					body.set_target_group("enemy")
					_charmed_bodies.append(body)
		if _charmed_bodies.size() == 0:
			_is_recharging = true
			_timer.wait_time = recharge_time
		else:
			_timer.wait_time = charm_time
			print("Charmed enemy(s)")
		_can_charm = false
		_timer.start()


func _on_Timer_timeout():
	if _is_recharging:
		_is_recharging = false
		_can_charm = true
	else:
		for body in _charmed_bodies:
			# In case body was removed (killed) before being uncharmed
			if weakref(body).get_ref():
				body.set_target_group("player")
		_charmed_bodies = []
		_is_recharging = true
		_timer.wait_time = recharge_time
		_timer.start()
