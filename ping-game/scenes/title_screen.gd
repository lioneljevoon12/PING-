extends Control

# Node References
@onready var play_button: TextureButton = %PlayButton
@onready var login_button: TextureButton = %LoginButton
@onready var router_mascot: TextureRect = %RouterMascot
@onready var packet_mascot: TextureRect = %PacketMascot
@onready var star_top_right: Label = %StarTopRight
@onready var star_bottom_left: Label = %StarBottomLeft
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var auth_modal: Control = %AuthModal
@onready var user_greeting_label: Label = %UserGreetingLabel
@onready var greeting_badge: PanelContainer = %GreetingBadge

# Animation state variables
var time_passed: float = 0.0
var router_base_pos: Vector2
var packet_base_pos: Vector2

func _ready() -> void:
	# Set pivot offsets to center for smooth scaling animations
	await get_tree().process_frame
	_init_positions_and_pivots()
	
	# Connect button events
	_setup_button(play_button, "PLAY")
	_setup_button(login_button, "LOG-IN")
	
	# Update User Greeting
	_update_greeting(PlayerData.current_username)
	PlayerData.user_changed.connect(_update_greeting)
	
	# Greeting badge click to log in
	if greeting_badge:
		greeting_badge.gui_input.connect(_on_greeting_badge_gui_input)

func _update_greeting(username: String) -> void:
	if user_greeting_label:
		user_greeting_label.text = "Hello, %s!" % username
		
		# Animate small bounce on name update
		if greeting_badge:
			greeting_badge.pivot_offset = greeting_badge.size / 2.0
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(greeting_badge, "scale", Vector2(1.15, 1.15), 0.15)
			tween.tween_property(greeting_badge, "scale", Vector2(1.0, 1.0), 0.15)

func _on_greeting_badge_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play_sfx(659.25)
		if auth_modal:
			auth_modal.open("login")

func _init_positions_and_pivots() -> void:
	if router_mascot:
		router_base_pos = router_mascot.position
		router_mascot.pivot_offset = router_mascot.size / 2.0
		
	if packet_mascot:
		packet_base_pos = packet_mascot.position
		packet_mascot.pivot_offset = packet_mascot.size / 2.0
		
	if star_top_right:
		star_top_right.pivot_offset = star_top_right.size / 2.0
	if star_bottom_left:
		star_bottom_left.pivot_offset = star_bottom_left.size / 2.0

func _setup_button(btn: TextureButton, btn_name: String) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size / 2.0
	
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(1.05, 1.05))
		play_sfx(659.25) # E5 note
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(1.0, 1.0))
	)
	btn.button_down.connect(func():
		btn.pivot_offset = btn.size / 2.0
		_animate_button_scale(btn, Vector2(0.95, 0.95))
		play_sfx(880.0) # A5 note
	)
	btn.button_up.connect(func():
		btn.pivot_offset = btn.size / 2.0
		var target = Vector2(1.05, 1.05) if btn.is_hovered() else Vector2(1.0, 1.0)
		_animate_button_scale(btn, target)
	)
	btn.pressed.connect(func():
		_on_button_clicked(btn_name)
	)

func _animate_button_scale(btn: TextureButton, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.12)

func _process(delta: float) -> void:
	time_passed += delta
	
	# Smooth floating animation for Router mascot
	if router_mascot and router_base_pos != Vector2.ZERO:
		router_mascot.position.y = router_base_pos.y + sin(time_passed * 2.2) * 10.0
		router_mascot.rotation_degrees = sin(time_passed * 1.6) * 1.8
	
	# Smooth floating & bobbing animation for Packet mascot
	if packet_mascot and packet_base_pos != Vector2.ZERO:
		packet_mascot.position.y = packet_base_pos.y + cos(time_passed * 2.6) * 12.0
		packet_mascot.rotation_degrees = cos(time_passed * 2.0) * -2.5

	# Twinkle stars
	if star_top_right:
		var s1 = 1.0 + 0.18 * sin(time_passed * 3.5)
		star_top_right.scale = Vector2(s1, s1)
	if star_bottom_left:
		var s2 = 1.0 + 0.18 * cos(time_passed * 3.0)
		star_bottom_left.scale = Vector2(s2, s2)

func _on_button_clicked(button_name: String) -> void:
	match button_name:
		"PLAY":
			print("Memulai Game untuk user: %s" % PlayerData.current_username)
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
		var t = float(i) / sample_rate
		var envelope = exp(-t * 40.0)
		var sample_val = sin(t * freq * TAU) * envelope * 0.4
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
