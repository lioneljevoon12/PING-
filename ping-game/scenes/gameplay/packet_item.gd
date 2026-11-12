class_name PacketItem
extends PanelContainer

# Komponen reusable untuk paket data IPv4 yang dapat di-drag dan di-tap.
# Sesuai spesifikasi: amplop bersayap dari folder Sprite animation/paket data,
# menampilkan nomor paket, oktet pertama dalam kotak oranye, dan sisa alamat IP.

const IPClassifier = preload("res://scripts/ip_classifier.gd")

signal drag_started(item: Control)
signal drag_ended(item: Control, global_drop_pos: Vector2)
signal selected(item: Control)

@export var packet_index: int = 1
var packet_data: Dictionary = {}

var is_locked: bool = false
var is_selected: bool = false
var is_dragging: bool = false
var has_moved: bool = false

var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var home_global_pos: Vector2 = Vector2.ZERO
var home_parent: Node = null
var home_index: int = 0

var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var tex_envelope: Texture2D = null

var style_normal: StyleBoxFlat
var style_hover: StyleBoxFlat
var style_selected: StyleBoxFlat
var style_dragging: StyleBoxFlat

@onready var envelope_rect: TextureRect = %EnvelopeRect
@onready var index_label: Label = %IndexLabel
@onready var octet_pill: PanelContainer = %OctetPill
@onready var octet_label: Label = %OctetLabel
@onready var rest_ip_label: Label = %RestIPLabel

func _ready() -> void:
	custom_minimum_size = Vector2(165, 82)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	_setup_styles()
	_apply_style(style_normal)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	tex_envelope = _safe_load_texture("res://art/assets/PING! Assets/Sprite animation/paket data/1.png")
	if envelope_rect and tex_envelope:
		envelope_rect.texture = tex_envelope
		
	if packet_data.is_empty():
		set_packet_info(packet_index, IPClassifier.generate_packet_data("A"))

func _setup_styles() -> void:
	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#ffffff")
	style_normal.border_color = Color("#3b82f6")
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(14)
	style_normal.shadow_color = Color(0, 0, 0, 0.10)
	style_normal.shadow_size = 4
	style_normal.shadow_offset = Vector2(0, 2)
	style_normal.set_content_margin_all(8)
	
	style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#f0f7ff")
	style_hover.border_color = Color("#2563eb")
	style_hover.set_border_width_all(2.5)
	style_hover.set_corner_radius_all(14)
	style_hover.shadow_color = Color(0.15, 0.39, 0.92, 0.22)
	style_hover.shadow_size = 6
	style_hover.shadow_offset = Vector2(0, 2)
	style_hover.set_content_margin_all(8)
	
	style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color("#eff6ff")
	style_selected.border_color = Color("#f59e0b")
	style_selected.set_border_width_all(3.5)
	style_selected.set_corner_radius_all(14)
	style_selected.shadow_color = Color(0.96, 0.62, 0.04, 0.35)
	style_selected.shadow_size = 8
	style_selected.shadow_offset = Vector2(0, 3)
	style_selected.set_content_margin_all(8)
	
	style_dragging = StyleBoxFlat.new()
	style_dragging.bg_color = Color("#ffffff")
	style_dragging.border_color = Color("#f59e0b")
	style_dragging.set_border_width_all(3)
	style_dragging.set_corner_radius_all(14)
	style_dragging.shadow_color = Color(0, 0, 0, 0.28)
	style_dragging.shadow_size = 12
	style_dragging.shadow_offset = Vector2(0, 6)
	style_dragging.set_content_margin_all(8)

func _apply_style(sb: StyleBoxFlat) -> void:
	add_theme_stylebox_override("panel", sb)

func _on_mouse_entered() -> void:
	if not is_selected and not is_dragging and not is_locked:
		_apply_style(style_hover)

func _on_mouse_exited() -> void:
	if not is_selected and not is_dragging and not is_locked:
		_apply_style(style_normal)

func set_packet_info(idx: int, data: Dictionary) -> void:
	packet_index = idx
	packet_data = data
	
	if index_label:
		index_label.text = "PAKET DATA #%02d" % idx
	if octet_label:
		octet_label.text = str(data.get("first_octet", 1))
	if rest_ip_label:
		rest_ip_label.text = str(data.get("rest", ".0.0.1"))

func set_firewall_info(idx: int, data: Dictionary) -> void:
	packet_index = idx
	packet_data = data
	
	if index_label:
		index_label.text = "TRAFIK MASUK #%02d" % idx
		index_label.add_theme_color_override("font_color", Color("#1e40af"))
	if octet_pill:
		octet_pill.visible = false
	if rest_ip_label:
		rest_ip_label.text = str(data.get("ip", "192.168.1.1"))
		rest_ip_label.add_theme_font_override("font", font_black)
		rest_ip_label.add_theme_font_size_override("font_size", 14)
		rest_ip_label.add_theme_color_override("font_color", Color("#1e293b"))
		rest_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rest_ip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_selected(val: bool) -> void:
	is_selected = val
	_apply_style(style_selected if is_selected else style_normal)

func save_home_position() -> void:
	home_global_pos = global_position
	home_parent = get_parent()
	home_index = get_index()

func animate_return_home() -> void:
	is_locked = true
	is_dragging = false
	z_index = 50
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", home_global_pos, 0.22)
	
	await tw.finished
	z_index = 0
	is_locked = false
	_apply_style(style_selected if is_selected else style_normal)

func animate_success_absorb(target_global_pos: Vector2, on_complete: Callable) -> void:
	is_locked = true
	is_dragging = false
	z_index = 60
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position", target_global_pos, 0.25)
	tw.tween_property(self, "scale", Vector2(0.2, 0.2), 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	
	await tw.finished
	if on_complete.is_valid():
		on_complete.call()
	queue_free()

func animate_shake_error() -> void:
	is_locked = true
	var orig_pos = position
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(3):
		tw.tween_property(self, "position:x", orig_pos.x - 8.0, 0.04)
		tw.tween_property(self, "position:x", orig_pos.x + 8.0, 0.04)
	tw.tween_property(self, "position:x", orig_pos.x, 0.04)
	await tw.finished
	is_locked = false

func _gui_input(event: InputEvent) -> void:
	if is_locked:
		return
		
	# Mouse Button input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag_tracking(event.global_position)
			else:
				_end_drag_tracking(event.global_position)
				
	# Mouse Motion input
	elif event is InputEventMouseMotion:
		_process_motion(event.global_position)
		
	# Touch input (Mobile)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag_tracking(event.position)
		else:
			_end_drag_tracking(event.position)
			
	# Screen Drag input (Mobile)
	elif event is InputEventScreenDrag:
		_process_motion(event.position)

func _start_drag_tracking(click_pos: Vector2) -> void:
	drag_start_mouse_pos = click_pos
	drag_offset = click_pos - global_position
	has_moved = false
	is_dragging = false
	save_home_position()

func _process_motion(current_pos: Vector2) -> void:
	if not has_moved and current_pos.distance_to(drag_start_mouse_pos) > 10.0:
		has_moved = true
		is_dragging = true
		z_index = 100
		_apply_style(style_dragging)
		drag_started.emit(self)
		
	if is_dragging:
		var target_pos = current_pos - drag_offset
		var vp_sz = get_viewport_rect().size
		target_pos.x = clamp(target_pos.x, 10.0, vp_sz.x - size.x - 10.0)
		target_pos.y = clamp(target_pos.y, 10.0, vp_sz.y - size.y - 10.0)
		global_position = target_pos

func _end_drag_tracking(release_pos: Vector2) -> void:
	if is_dragging:
		is_dragging = false
		drag_ended.emit(self, release_pos)
	else:
		set_selected(not is_selected)
		selected.emit(self)

static func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var global_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
