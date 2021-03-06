extends Node2D

signal selected(item_id)

onready var _pedestal_sprite = $PedestalSprite
onready var _select_area = $SelectArea
onready var _animation_player = $AnimationPlayer

export(String) var item_id = "NONE"
export(bool) var disabled = false

var _item = null
var _can_select


func disable():
	_pedestal_sprite.visible = false
	_select_area.monitoring = false

func enable():
	_pedestal_sprite.visible = true
	_select_area.monitoring = true


func _ready():
	if disabled:
		disable()
	else:
		enable()
	_item = Items.get_item_sprite(item_id)
	if _item != null:
		add_child(_item)
		_item.get_node("AnimationPlayer").play("animated")


func _input(event):
	if event.is_action_pressed("ui_accept") and _can_select and not disabled:
		emit_signal("selected", item_id)
		_can_select = false


func _on_SelectArea_body_entered(_body):
	if not disabled:
		_can_select = true
		_animation_player.play("show_input")

func _on_SelectArea_body_exited(_body):
	if not disabled:
		_can_select = false
		_animation_player.play("hide_input")
