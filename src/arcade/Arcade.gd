extends Node2D

onready var node_joy := $Cabinet/Controls/Joystick
onready var node_a := $Cabinet/Controls/Button/Control/Node2D
onready var node_b := $Cabinet/Controls/Button2/Control/Node2D

var joy := Vector2.ZERO
var btn_a := false
var btn_b := false
var is_unpause := false

func _ready():
	MenuPause.connect("opened", self, "pause")

func _physics_process(delta):
	var m = MenuPause.is_paused
	
	joy.x = 0.0 if m else round(Input.get_axis("left", "right"))
	var a = Input.is_action_pressed("jump")
	var b = Input.is_action_pressed("grab")
	
	if is_unpause: is_unpause = a or b
	if !is_unpause:
		btn_a = a and !m
		btn_b = b and !m
	
	node_joy.rotation = lerp(node_joy.rotation, joy.x * deg2rad(15), delta * 30.0)
	node_a.position.y = lerp(node_a.position.y, float(btn_a) * 20, delta * 30.0)
	node_b.position.y = lerp(node_b.position.y, float(btn_b) * 20, delta * 30.0)

func pause(arg := false):
	is_unpause = !arg
