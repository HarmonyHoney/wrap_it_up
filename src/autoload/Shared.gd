extends Node

export var is_debug := false
export var time_scale := 1.0 setget set_time_scale
export var iterations := 60 setget set_iterations
export var target_fps := 0.0 setget set_target_fps

var splash_path := "res://src/menu/Splash.tscn"
var arcade_path := "res://src/arcade/Arcade.tscn"
onready var csfn := get_tree().current_scene.filename
onready var last_scene := csfn
onready var next_scene := csfn
signal scene_before
signal scene_changed
var arcade
var is_web := false

enum SPEED {OFF, MAP, FILE, BOTH, TRADE}
var clock_show := 0 setget set_clock_show
var clock_alpha := 1.0 setget set_clock_alpha
var clock_decimals := 2
var save_time := 0.0
var default_keys := {}
var is_gamepad := false
signal gamepad_input(arg)

var volume = [100, 100, 100, 100]
var win_size := Vector2(720, 720)
var win_sizes := [Vector2(360, 360), Vector2(540, 540), Vector2(720, 720), Vector2(900, 900),
Vector2(1080, 1080), Vector2(1440, 1440), Vector2(2160, 2160)]
var is_interpolate := true setget set_is_interpolate

func _ready():
	is_web = OS.get_name() == "HTML5"
	
	for i in [1, 2]:
		set_volume(i, 50)
	
	# get default key binds
	for i in InputMap.get_actions():
		default_keys[i] = InputMap.get_action_list(i)
	
	load_options()
	load_keys()
	
	# setup window
	if !is_web:
		if OS.window_fullscreen:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			win_size = OS.window_size
			
			# center window
			set_window_size()
	
	yield(get_tree(), "idle_frame")
	set_is_interpolate()
	set_clock_show()

func _input(event):
	if event is InputEventKey and event.pressed and !event.is_echo():
		if event.scancode == KEY_F11:
			toggle_fullscreen()
	
	# gamepad signal
	if event.is_pressed():
		var g = is_gamepad
		if is_gamepad and event is InputEventKey:
			is_gamepad = false
		elif !is_gamepad and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			is_gamepad = true
		
		if g != is_gamepad:
			emit_signal("gamepad_input", is_gamepad)
			print("gamepad_input: ", is_gamepad)
	
	if is_debug:
		
		for i in ["screenshot", "reset"]:
			var p = event.is_action_pressed("debug_" + i)
			if !p: continue
			
			match i:
				"screenshot":
					burst_screenshot(15)
				"reset":
					reset()


func _process(delta):
	# recorded time
	save_time += delta
	
	# clock label
	UI.clock_file.text = time_string(save_time, clock_decimals)

func time_string(t := 0.0, dec = 2, is_min := false, is_hour := false):
	# time
	var s_hour = str(int(t) / 3600) + ":" if is_hour or t > 3600 else ""
	var s_min = str((int(t) / 60) % 60).pad_zeros(2 if s_hour else 0) + ":" if is_min or t > 60 else ""
	var s_sec = str(fmod(t, 60)).pad_zeros(2).pad_decimals(dec)
	
	return s_hour + s_min + s_sec

func reset():
	change_scene(csfn)

func change_scene(arg := ""):
	var f = File.new()
	var fe = arg != "" and f.file_exists(arg)
	f.close()
	if !fe: return
	
	emit_signal("scene_before")
	
	csfn = arg
	get_tree().change_scene(csfn)
	
	yield(get_tree(), "idle_frame")
	
	emit_signal("scene_changed")

func toggle_fullscreen():
	OS.window_fullscreen = !OS.window_fullscreen
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if OS.window_fullscreen else Input.MOUSE_MODE_VISIBLE)
	if !OS.window_fullscreen:
		set_window_size()

func set_window_size(arg : Vector2 = win_size):
	win_size = arg
	# specific fix for borderless fullscreen
	var b = OS.window_borderless and win_size == OS.get_screen_size()
	OS.window_size = win_size + Vector2(2 if b else 0, 0)
	OS.window_position = Vector2(-1, 0) if b else (OS.get_screen_size() * 0.5) - (OS.window_size * 0.5)

func burst_screenshot(count := 30, viewport := get_tree().root):
	var dir := Directory.new()
	if !dir.dir_exists("user://snap"):
		dir.make_dir("user://snap")
	
	var images = []
	
	for i in count:
		var image = viewport.get_texture().get_data()
		image.flip_y()
		images.append(image)
		yield(get_tree(), "idle_frame")
	
	var d = OS.get_datetime()
	d.erase("dst")
	var s = ""
	
	for i in (d.values()):
		s += str(i) + " "
	
	for i in images.size():
		images[i].save_png("user://snap/" + s + "snap" + str(i) + ".png")
		yield(get_tree(), "idle_frame")

### Useful funcs

func get_all_children(n, a := []):
	if is_instance_valid(n):
		a.append(n)
		for i in n.get_children():
			a = get_all_children(i, a)
	return a

### Options

func set_volume(bus = 0, vol = 0):
	volume[bus] = clamp(vol, 0, 100)
	AudioServer.set_bus_volume_db(bus, linear2db(volume[bus] / 100.0))
	#print("volume[", bus, "] ",AudioServer.get_bus_name(bus) ," : ", volume[bus])

func set_is_interpolate(arg := is_interpolate):
	is_interpolate = bool(arg)

func set_clock_show(arg := clock_show):
	clock_show = abs(arg)
	if is_instance_valid(UI.clock_file):
		UI.clock_file.visible = clock_show > 0

func set_clock_alpha(arg := clock_alpha):
	clock_alpha = clamp(arg, 0, 1)
	if is_instance_valid(UI.clock):
		UI.clock.modulate.a = clock_alpha

func set_time_scale(arg := time_scale):
	time_scale = arg
	Engine.time_scale = time_scale

func set_iterations(arg := iterations):
	iterations = max(1, arg)
	Engine.iterations_per_second = iterations

func set_target_fps(arg := target_fps):
	target_fps = abs(arg)
	#print("target_fps: ", target_fps)
	Engine.target_fps = target_fps

### Exit Game

func quit():
	save_options()
	get_tree().quit()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		quit()

### Files and Directory Funcs ###

func list_folder(path, include_extension := true):
	var dir = Directory.new()
	if dir.open(path) != OK:
		print("list_folder(): '", path, "' not found")
		return
	
	var list = []
	dir.list_dir_begin(true)
	
	var fname = dir.get_next()
	while fname != "":
		list.append(fname if include_extension else fname.split(".")[0])
		fname = dir.get_next()
	
	dir.list_dir_end()
	return list

func list_all_files(path, is_ext := true):
	var folders = [path]
	var files = []
	
	while !folders.empty():
		var s = folders.pop_back()
		
		var ex = list_folders_and_files(s, is_ext)
		folders.append_array(ex[0])
		files.append_array(ex[1])
	
	return files

func list_folders_and_files(path, is_ext := true):
	var dir = Directory.new()
	if dir.open(path) != OK:
		print("list_folders_and_files(): '", path, "' not found")
		return
	
	dir.list_dir_begin(true)
	var fname = dir.get_next()
	var files := []
	var folders := []
	
	while fname != "":
		var s = dir.get_current_dir() + "/" + (fname if is_ext else fname.split(".")[0])
		folders.append(s) if dir.current_is_dir() else files.append(s)
		fname = dir.get_next()
	
	dir.list_dir_end()
	return [folders, files]

func file_save(path : String, content : String):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()

func file_save_json(path : String, dict : Dictionary):
	var j = JSON.print(dict, "\t")
	file_save(path, j)

func file_load(path : String) -> String:
	var content = ""
	
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		content = file.get_as_text()
	file.close()
	
	return content

func file_load_json_dict(path : String):
	var d := {}
	
	var j = file_load(path)
	if j != "":
		var p = JSON.parse(j)
		if typeof(p.result) == TYPE_DICTIONARY:
			d = p.result
	
	return d

func save_options():
	var o := {}
	
	o["sounds"] = int(volume[1] / 10)
	o["music"] = int(volume[2] / 10)
	
	o["mouse"] = int(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	o["is_interpolate"] = int(is_interpolate)
	
	o["clock_show"] = int(clock_show)
	o["clock_alpha"] = float(clock_alpha)
	o["clock_decimals"] = int(clock_decimals)
	
	file_save_json("user://options.json", o)
	
	# override
	var s = "[display/window]\n\n"
	if win_size != Vector2(1280, 720):
		s += "size/test_width=" + str(win_size.x) + "\n"
		s += "size/test_height=" + str(win_size.y) + "\n"
	s += "size/borderless=" + str(OS.window_borderless).to_lower() + "\n"
	s += "size/fullscreen=" + str(OS.window_fullscreen).to_lower() + "\n"
	s += "vsync/use_vsync=" + str(OS.vsync_enabled).to_lower() + "\n"
	
	file_save("user://override.cfg", s)

func load_options():
	var d = file_load_json_dict("user://options.json")
	
	if d.has("sounds"):
		set_volume(1, int(d["sounds"]) * 10)
	if d.has("music"):
		set_volume(2, int(d["music"]) * 10)
	
	if d.has("mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if int(d["mouse"]) else Input.MOUSE_MODE_HIDDEN
	if d.has("is_interpolate"):
		self.is_interpolate = int(d["is_interpolate"])
	
	if d.has("clock_show"):
		clock_show = int(d["clock_show"])
	if d.has("clock_alpha"):
		clock_alpha = float(d["clock_alpha"])
	if d.has("clock_decimals"):
		clock_decimals = int(d["clock_decimals"])

func save_keys(path := "user://keys.tres"):
	var s_keys = SaveDict.new()
	for a in InputMap.get_actions():
		s_keys.dict[a] = InputMap.get_action_list(a)
	
	ResourceSaver.save(path, s_keys)

func load_keys(path := "user://keys.tres"):
	if !ResourceLoader.exists(path): return
	var r = load(path)
	
	if r is SaveDict:
		for a in r.dict.keys():
			if InputMap.has_action(a):
				InputMap.action_erase_events(a)
				
				for e in r.dict[a]:
					InputMap.action_add_event(a, e)

### Steam ###
func achieve(arg := ""):
	if arg != "":
		pass # set achievement (:
