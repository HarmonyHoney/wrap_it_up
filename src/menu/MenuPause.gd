extends MenuBase

var is_paused := false

func _input(event):
	if is_open:
		if event.is_action_pressed("ui_pause") and !is_sub_menu and (fade_ease.frac() > 0.5):
			self.is_open = false
		else:
			menu_input(event)
	elif event.is_action_pressed("ui_pause") and !is_sub_menu:
		self.is_open = true

func accept():
	joy = Vector2.ZERO
	match items[cursor].name.to_lower():
		"resume":
			self.is_open = false
		"reset":
			Shared.reset()
			self.is_open = false
		"options":
			sub_menu(MenuOptions)
		"quit":
			Shared.quit()

func wipe_complete(arg):
	if is_open:
		# close menu
		set_open(false, false)
		fade_ease.clock = 0

func set_open(arg := is_open, is_audio := true):
	.set_open(arg)
	is_paused = is_open
	
	# setup items
	if is_open:
		items = []
		for i in items_node.get_children():
			if i.visible:
				items.append(i)
	
	if is_audio:
		Audio.play("menu_pause", 1.0 if is_open else 0.75)

