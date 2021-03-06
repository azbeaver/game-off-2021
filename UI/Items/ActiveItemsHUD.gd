extends Control

onready var _box1 = $ActiveItemBox1
onready var _box2 = $ActiveItemBox2

var _box1_id = ""
var _box2_id = ""

func set_item(box : int, item_id : String):
	if box == 1:
		_box1.remove_item()
		_box1_id = item_id
		_box1.set_item(item_id)
	elif box == 2:
		_box2.remove_item()
		_box2_id = item_id
		_box2.set_item(item_id)


func get_item_id(box : int):
	if box == 1:
		return _box1_id
	elif box == 2:
		return _box2_id


func remove_items():
	_box1.remove_item()
	_box1_id = ""
	_box2.remove_item()
	_box2_id = ""


func inactive(action_num):
	if action_num == 1:
		_box1.inactive()
	elif action_num == 2:
		_box2.inactive()

func active(action_num):
	if action_num == 1:
		_box1.active()
	elif action_num == 2:
		_box2.active()


func open():
	modulate = Color(1.0, 1.0, 1.0, 1.0)
func close():
	modulate = Color(1.0, 1.0, 1.0, 0.0)


func _ready():
	close()


func _input(event):
	if event.is_action_pressed("ui_accept"):
		_box1.bump()
	if event.is_action_pressed("ui_select"):
		_box2.bump()
