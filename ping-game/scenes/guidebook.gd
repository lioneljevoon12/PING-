extends Control

signal closed

@onready var dim_backdrop: ColorRect = %DimBackdrop
@onready var book_wrapper: Control = %BookWrapper
@onready var close_btn: TextureButton = %CloseButton
@onready var prev_btn: Button = %PrevButton
@onready var next_btn: Button = %NextButton
@onready var prev_dimmer: ColorRect = %PrevDimmer
@onready var next_dimmer: ColorRect = %NextDimmer

# Left page nodes
@onready var left_title: Label = %LeftTitle
@onready var left_image: TextureRect = %LeftImage
@onready var left_text: RichTextLabel = %LeftText
@onready var page_num_left: Label = %PageNumLeft

# Right page nodes
@onready var right_title: Label = %RightTitle
@onready var right_text: RichTextLabel = %RightText
@onready var right_image: TextureRect = %RightImage
@onready var page_num_right: Label = %PageNumRight

# Flipping sheet animation nodes
@onready var flip_sheet: Control = %FlipSheet
@onready var sheet_shadow: ColorRect = %SheetShadow
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var current_spread: int = 0
var is_animating: bool = false
var book_tween: Tween

# Textures
var tex_straight: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight_opt.png")
var tex_cross: Texture2D = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/cross_opt.png")
var tex_crimping: Texture2D = preload("res://art/assets/PING! Assets/Objects/Crimping.png")
var tex_cable: Texture2D = preload("res://art/assets/PING! Assets/Objects/kabel utp.png")

var spreads: Array = [
	{
		"left": {
			"title": "KABEL STRAIGHT (T568B)",
			"image": tex_straight,
			"image_height": 135,
			"desc": "[b][color=#166534]🔌 Penggunaan (Perangkat BERBEDA):[/color][/b]\n• PC ↔ Switch / Hub       • Router ↔ Switch\n\n[b][color=#166534]📋 Urutan Warna Pin T568B (Kedua Ujung SAMA):[/color][/b]\n[table=2]\n[cell][b]1.[/b] Putih-Oranye   [/cell][cell][b]5.[/b] Putih-Biru[/cell]\n[cell][b]2.[/b] Oranye         [/cell][cell][b]6.[/b] Hijau[/cell]\n[cell][b]3.[/b] Putih-Hijau    [/cell][cell][b]7.[/b] Putih-Cokelat[/cell]\n[cell][b]4.[/b] Biru           [/cell][cell][b]8.[/b] Cokelat[/cell]\n[/table]\n[i][color=#4b5563]💡 Kabel paling umum digunakan di jaringan lokal.[/color][/i]"
		},
		"right": {
			"title": "KABEL CROSSOVER (T568A/B)",
			"image": tex_cross,
			"image_height": 135,
			"body": "[b][color=#991b1b]⚡ Penggunaan (Perangkat SEJENIS):[/color][/b]\n• PC ↔ PC   • Switch ↔ Switch   • Router ↔ Router\n\n[b][color=#92400e]⭐ RUMUS SILANG (Pin 1&2 tukar Pin 3&6):[/color][/b]\n[table=2]\n[cell][b]1.[/b] Putih-Hijau (dari 3) [/cell][cell][b]5.[/b] Putih-Biru (tetap)[/cell]\n[cell][b]2.[/b] Hijau (dari 6)        [/cell][cell][b]6.[/b] Oranye (dari 2)[/cell]\n[cell][b]3.[/b] Putih-Oranye (dari 1) [/cell][cell][b]7.[/b] Putih-Cokelat (tetap)[/cell]\n[cell][b]4.[/b] Biru (tetap)          [/cell][cell][b]8.[/b] Cokelat (tetap)[/cell]\n[/table]\n[i][color=#4b5563]💡 Ujung 1 berstandar T568A, ujung 2 berstandar T568B.[/color][/i]"
		}
	},
	{
		"left": {
			"title": "FUNGSI PIN RJ-45",
			"image": tex_cable,
			"image_height": 115,
			"desc": "[b][color=#1e3a8a]Fungsi Jalur Pin RJ-45 (Ethernet 10/100):[/color][/b]\n• [b]Pin 1 & 2:[/b] Transmit Data (Tx+ / Tx-)\n• [b]Pin 3 & 6:[/b] Receive Data (Rx+ / Rx-)\n• [b]Pin 4, 5, 7, 8:[/b] Cadangan / Power over Ethernet (PoE)\n\n[b][color=#b45309]Perbedaan T568A vs T568B:[/color][/b]\nHanya menukar pasangan warna [color=#ea580c][b]Oranye[/b][/color] dan [color=#16a34a][b]Hijau[/b][/color] (Pin 1, 2 ditukar dengan Pin 3, 6)."
		},
		"right": {
			"title": "LANGKAH CRIMPING",
			"image": tex_crimping,
			"image_height": 115,
			"body": "[b][color=#166534]Urutan Pemasangan Kabel LAN UTP:[/color][/b]\n[b]1. Kupas Jaket:[/b] Kupas jaket pelindung luar ~2 cm.\n[b]2. Urai & Luruskan:[/b] Buka 4 pilinan pasang kawat.\n[b]3. Susun Warna:[/b] Urutkan pin sesuai standar T568B.\n[b]4. Potong Rata:[/b] Potong rata ujung kawat ~1.2 cm.\n[b]5. Tekan Crimping:[/b] Masukkan ke konektor RJ-45 lalu jepit erat dengan tang crimping hingga mengunci!"
		}
	},
	{
		"left": {
			"title": "KLASIFIKASI IPv4",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Pembagian Kelas Alamat IPv4:[/color][/b]\n\n• [b]Kelas A (1.0.0.0 – 126.255.255.255):[/b]\n  Subnet Mask /8 (255.0.0.0)\n  Skala: Jaringan global sangat besar (16 Juta Host)\n\n• [b]Kelas B (128.0.0.0 – 191.255.255.255):[/b]\n  Subnet Mask /16 (255.255.0.0)\n  Skala: Kampus / Perusahaan skala besar (65.534 Host)\n\n• [b]Kelas C (192.0.0.0 – 223.255.255.255):[/b]\n  Subnet Mask /24 (255.255.255.0)\n  Skala: Jaringan LAN lokal & rumah (254 Host)"
		},
		"right": {
			"title": "IP PRIVAT & NAT",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#047857]Rentang IP Privat (Gratis untuk LAN):[/color][/b]\n• [b]Kelas A:[/b] 10.0.0.0 – 10.255.255.255\n• [b]Kelas B:[/b] 172.16.0.0 – 172.31.255.255\n• [b]Kelas C:[/b] 192.168.0.0 – 192.168.255.255\n\n[b][color=#b45309]Mekanisme NAT (Network Address Translation):[/color][/b]\nIP privat tidak dapat dirutekan langsung di Internet publik. Router menggunakan fitur [b]NAT[/b] untuk menerjemahkan banyak IP privat lokal ke satu IP publik resmi saat berkomunikasi ke luar jaringan."
		}
	}
]

func _ready() -> void:
	visible = false
	book_wrapper.pivot_offset = book_wrapper.size / 2.0
	
	close_btn.pivot_offset = close_btn.size / 2.0
	prev_btn.pivot_offset = prev_btn.size / 2.0
	next_btn.pivot_offset = next_btn.size / 2.0
	
	close_btn.pressed.connect(close)
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	
	_setup_scale_feedback(close_btn)
	_setup_scale_feedback(prev_btn)
	_setup_scale_feedback(next_btn)
	
	dim_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	
	_render_spread(current_spread)
	
	if "--screenshot-guidebook" in OS.get_cmdline_args():
		open(0)
		await get_tree().create_timer(0.45).timeout
		var img0 = get_viewport().get_texture().get_image()
		img0.save_png("art/guidebook_spread0.png")
		
		# Next spread
		_on_next_pressed()
		await get_tree().create_timer(0.45).timeout
		var img1 = get_viewport().get_texture().get_image()
		img1.save_png("art/guidebook_spread1.png")
		
		# Next spread
		_on_next_pressed()
		await get_tree().create_timer(0.45).timeout
		var img2 = get_viewport().get_texture().get_image()
		img2.save_png("art/guidebook_spread2.png")
		
		get_tree().quit()

func open(target_spread: int = 0) -> void:
	visible = true
	is_animating = false
	current_spread = clamp(target_spread, 0, spreads.size() - 1)
	_render_spread(current_spread)
	
	dim_backdrop.modulate.a = 0.0
	book_wrapper.modulate.a = 0.0
	book_wrapper.scale = Vector2(0.4, 0.4)
	
	if book_tween and book_tween.is_valid():
		book_tween.kill()
		
	book_tween = create_tween().set_parallel(true)
	book_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	book_tween.tween_property(dim_backdrop, "modulate:a", 1.0, 0.25)
	book_tween.tween_property(book_wrapper, "modulate:a", 1.0, 0.2)
	book_tween.tween_property(book_wrapper, "scale", Vector2.ONE, 0.32)
	
	play_book_open_sfx()

func close() -> void:
	if is_animating:
		return
	is_animating = true
	play_book_close_sfx()
	
	if book_tween and book_tween.is_valid():
		book_tween.kill()
		
	book_tween = create_tween().set_parallel(true)
	book_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	book_tween.tween_property(dim_backdrop, "modulate:a", 0.0, 0.2)
	book_tween.tween_property(book_wrapper, "modulate:a", 0.0, 0.2)
	book_tween.tween_property(book_wrapper, "scale", Vector2(0.4, 0.4), 0.22)
	
	book_tween.chain().tween_callback(func():
		visible = false
		is_animating = false
		closed.emit()
	)

func _on_next_pressed() -> void:
	if is_animating or current_spread >= spreads.size() - 1:
		return
	_flip_page(true)

func _on_prev_pressed() -> void:
	if is_animating or current_spread <= 0:
		return
	_flip_page(false)

func _flip_page(forward: bool) -> void:
	is_animating = true
	play_page_flip_sfx()
	
	flip_sheet.visible = true
	
	var flip_duration = 0.16
	var next_index = current_spread + 1 if forward else current_spread - 1
	
	if forward:
		# Flip from right to left across spine
		flip_sheet.position = Vector2(444, 28)
		flip_sheet.size = Vector2(396, 518)
		flip_sheet.pivot_offset = Vector2(0, 259) # Left edge (spine)
		flip_sheet.scale = Vector2(1.0, 1.0)
		sheet_shadow.color.a = 0.0
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(flip_sheet, "scale:x", 0.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.35, flip_duration)
		
		tween.chain().tween_callback(func():
			current_spread = next_index
			_render_spread(current_spread)
			
			flip_sheet.position = Vector2(34, 28)
			flip_sheet.pivot_offset = Vector2(396, 259) # Right edge (spine)
			flip_sheet.scale = Vector2(0.0, 1.0)
		)
		
		tween.chain().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(flip_sheet, "scale:x", 1.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.0, flip_duration)
		
		tween.chain().tween_callback(func():
			flip_sheet.visible = false
			is_animating = false
		)
	else:
		# Flip from left to right across spine
		flip_sheet.position = Vector2(34, 28)
		flip_sheet.size = Vector2(396, 518)
		flip_sheet.pivot_offset = Vector2(396, 259) # Right edge (spine)
		flip_sheet.scale = Vector2(1.0, 1.0)
		sheet_shadow.color.a = 0.0
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(flip_sheet, "scale:x", 0.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.35, flip_duration)
		
		tween.chain().tween_callback(func():
			current_spread = next_index
			_render_spread(current_spread)
			
			flip_sheet.position = Vector2(444, 28)
			flip_sheet.pivot_offset = Vector2(0, 259) # Left edge (spine)
			flip_sheet.scale = Vector2(0.0, 1.0)
		)
		
		tween.chain().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(flip_sheet, "scale:x", 1.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.0, flip_duration)
		
		tween.chain().tween_callback(func():
			flip_sheet.visible = false
			is_animating = false
		)

func _render_spread(index: int) -> void:
	if index < 0 or index >= spreads.size():
		return
		
	var data = spreads[index]
	
	# Left Page
	left_title.text = data["left"]["title"]
	if data["left"]["image"]:
		left_image.texture = data["left"]["image"]
		var h = data["left"].get("image_height", 135)
		left_image.custom_minimum_size = Vector2(0, h)
		left_image.visible = true
	else:
		left_image.visible = false
	left_text.text = data["left"]["desc"]
	page_num_left.text = str(index * 2 + 1)
	
	# Right Page
	right_title.text = data["right"]["title"]
	right_text.text = data["right"]["body"]
	if data["right"]["image"]:
		right_image.texture = data["right"]["image"]
		var h = data["right"].get("image_height", 135)
		right_image.custom_minimum_size = Vector2(0, h)
		right_image.visible = true
	else:
		right_image.visible = false
	page_num_right.text = str(index * 2 + 2)
	
	# Button states & visual dimmers
	prev_btn.disabled = (index == 0)
	if prev_dimmer:
		prev_dimmer.visible = prev_btn.disabled
	
	next_btn.disabled = (index == spreads.size() - 1)
	if next_dimmer:
		next_dimmer.visible = next_btn.disabled

func _setup_scale_feedback(btn: Control) -> void:
	btn.mouse_entered.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.1)
	)
	btn.mouse_exited.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)
	if btn is Button:
		btn.button_down.connect(func():
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.08)
		)
		btn.button_up.connect(func():
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2.ONE, 0.1)
		)
	elif btn is TextureButton:
		btn.button_down.connect(func():
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.08)
		)
		btn.button_up.connect(func():
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2.ONE, 0.1)
		)

# Sound Synthesis: Book Open Chime
func play_book_open_sfx() -> void:
	_play_synth_tone([523.25, 659.25, 783.99], 0.16, 0.28)

# Sound Synthesis: Book Close Tone
func play_book_close_sfx() -> void:
	_play_synth_tone([783.99, 523.25], 0.12, 0.28)

# Sound Synthesis: Crisp Paper Turn Rustle
func play_page_flip_sfx() -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = sin(t / duration * PI) * exp(-t * 12.0)
		var noise = randf_range(-1.0, 1.0)
		var flutter = sin(t * 1200.0 * TAU) * 0.25
		var sample_val = (noise * 0.7 + flutter) * envelope * 0.35
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_synth_tone(notes: Array, note_duration: float, volume: float) -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var total_dur = note_duration * notes.size()
	var num_samples = int(sample_rate * total_dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t_total = float(i) / sample_rate
		var note_idx = int(t_total / note_duration)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var freq = notes[note_idx]
		var t_note = fmod(t_total, note_duration)
		var envelope = exp(-t_note * 18.0)
		var sample_val = sin(t_note * freq * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
