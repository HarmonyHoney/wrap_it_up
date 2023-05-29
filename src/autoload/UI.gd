extends CanvasLayer

var keys = EaseMover.new()

onready var clock := $Center/Control/Clock
onready var clock_file := $Center/Control/Clock/File
onready var keys_list := $Center/Control/Keys/List.get_children()

func _ready():
	keys.node = $Center/Control/Keys
	keys.to = keys.node.rect_position
	keys.from = keys.to + Vector2(0, 80)
	keys.show = false
	
	clock.modulate.a = Shared.clock_alpha

func _process(delta):
	keys.move(delta)

func menu_keys(accept := "", cancel := ""):
	var c = keys_list
	
	# accept
	var is_a = accept != ""
	c[0].visible = is_a # label
	c[0].text = accept
	c[1].visible = is_a # key
	
	# cancel
	var is_c = cancel != ""
	c[2].visible = is_c # spacer
	c[3].visible = is_c # label
	c[3].text = cancel
	c[4].visible = is_c # key
	
