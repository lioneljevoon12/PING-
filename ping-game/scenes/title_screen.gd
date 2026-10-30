extends Control

# Node References
@onready var play_button: Button = %PlayButton
@onready var login_button: Button = %LoginButton
@onready var logo_ping: TextureRect = %LogoPing
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var auth_modal: Control = %AuthModal
@onready var user_greeting_label: Label = %UserGreetingLabel
@onready var greeting_badge: PanelContainer = %GreetingBadge

var time_passed: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	
	# Connect button events
	_setup_button(play_button, "PLAY")
	_setup_button(login_button, "LOG-IN")
	
	# Update User Greeting
	_update_greeting(PlayerData.current_username)
	PlayerData.user_changed.connect(_update_greeting)
	
	# Greeting badge click to log in
	if greeting_badge:
		greeting_badge.gui_input.connect(_on_greeting_badge_gui_input)
		
	if "--screenshot-title" in OS.get_cmdline_args():
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/title_render.png")
		get_tree().quit()

func _update_greeting(username: String) -> void:
	if user_greeting_label:
		if username.is_empty() or username == "Tamu":
			user_greeting_label.text = "Halo, Player"
		else:
			user_greeting_label.text = "Halo, %s" % username
		
		# Animate small bounce on name update
		if greeting_badge:
			greeting_badge.pivot_offset = greeting_badge.size / 2.0
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(greeting_badge, "scale", Vector2(1.1, 1.1), 0.15)
			tween.tween_property(greeting_badge, "scale", Vector2(1.0, 1.0), 0.15)

func _on_greeting_badge_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		play_sfx(659.25)
		if auth_modal:
			auth_modal.open("login")

func _setup_button(btn: Button, btn_name: String) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size / 2.0
	
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(1.05, 1.05))
		play_sfx(659.25)
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(1.0, 1.0))
	)
	btn.button_down.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(0.95, 0.95))
		play_sfx(880.0)
	)
	btn.button_up.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var target = Vector2(1.05, 1.05) if btn.is_hovered() else Vector2(1.0, 1.0)
		_animate_button_scale(btn, target)
	)
	btn.pressed.connect(func():
		_on_button_clicked(btn_name)
	)

func _animate_button_scale(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.12)

func _process(delta: float) -> void:
	time_passed += delta
	# Subtle breathing pulse on PING! logo
	if logo_ping:
		var s = 1.0 + sin(time_passed * 1.8) * 0.015
		logo_ping.scale = Vector2(s, s)
		logo_ping.pivot_offset = logo_ping.size / 2.0

func _on_button_clicked(button_name: String) -> void:
	match button_name:
		"PLAY":
			print("Memulai Game untuk user: %s" % PlayerData.current_username)
			get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
		"LOG-IN":
			if auth_modal:
				auth_modal.open("login")

# Procedural Audio Synth for cute pop sounds
func play_sfx(freq: float) -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (float(i) / float(num_samples))
		var val = sin(2.0 * PI * freq * t) * env * 0.3
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
