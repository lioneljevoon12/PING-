class_name AccessoryOverlay
extends Control

# Aksesoris karakter yang menempel di posisi yang benar pada badan router:
#  - helm / topi: di atas "kepala" (tutup router), TIDAK menutupi wajah
#  - kacamata: tepat di atas mata (agak transparan)
#  - headset: di kedua sisi kepala
#  - pita: di sudut kiri atas
# Posisi mengikuti ukuran sprite dan ikut BERBALIK saat karakter menghadap kiri (flip_h).

# u, v = titik tengah aksesoris relatif terhadap kotak badan (0..1), w = lebar relatif terhadap lebar badan
const PLACEMENT := {
	"helmet": { "u": 0.50, "v": 0.29, "w": 0.42, "alpha": 1.0 },
	"visor": { "u": 0.60, "v": 0.66, "w": 0.40, "alpha": 0.65 },
	"headset": { "u": 0.50, "v": 0.37, "w": 0.66, "alpha": 1.0 },
	"grad_cap": { "u": 0.50, "v": 0.31, "w": 0.52, "alpha": 1.0 },
	"ribbon": { "u": 0.27, "v": 0.42, "w": 0.20, "alpha": 1.0 },
}

# Kotak badan bawaan bila gambar tidak bisa dibaca (relatif terhadap ukuran tekstur)
const FALLBACK_BODY := Rect2(0.28, 0.09, 0.42, 0.74)

static var _body_cache: Dictionary = {}
static var _acc_cache: Dictionary = {}

var sprite: TextureRect
var acc_id: String = ""
var acc_rect: TextureRect

# Pasang / perbarui aksesoris pada sebuah sprite karakter. id "none" atau tekstur null = hapus.
static func apply(sp: TextureRect, id: String, tex_path: String) -> void:
	if sp == null or not is_instance_valid(sp):
		return
	var ov = sp.get_node_or_null("AccessoryOverlay") as AccessoryOverlay
	if id == "none" or tex_path == "" or not ResourceLoader.exists(tex_path):
		if ov:
			ov.visible = false
		return
	if ov == null:
		# bila sebelumnya ada overlay versi lama (bukan AccessoryOverlay), buang
		var old = sp.get_node_or_null("AccessoryOverlay")
		if old:
			old.free()
		ov = AccessoryOverlay.new()
		ov.name = "AccessoryOverlay"
		ov.sprite = sp
		ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ov.set_anchors_preset(Control.PRESET_FULL_RECT)
		ov.acc_rect = TextureRect.new()
		ov.acc_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ov.acc_rect.stretch_mode = TextureRect.STRETCH_SCALE
		ov.acc_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ov.add_child(ov.acc_rect)
		sp.add_child(ov)
	ov.visible = true
	ov.acc_id = id
	ov.acc_rect.texture = _cropped_texture(tex_path)
	ov.acc_rect.modulate.a = float(PLACEMENT.get(id, { "alpha": 1.0 })["alpha"])
	ov._update_placement()

# Potong bagian transparan agar ukuran/penempatan akurat
static func _cropped_texture(path: String) -> Texture2D:
	if _acc_cache.has(path):
		return _acc_cache[path]
	var tex = load(path) as Texture2D
	var result: Texture2D = tex
	if tex:
		var img = tex.get_image()
		if img:
			var used = img.get_used_rect()
			if used.size.x > 0 and used.size.y > 0:
				var at = AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(used)
				result = at
	_acc_cache[path] = result
	return result

static func _body_rect(tex: Texture2D) -> Rect2:
	var key = "%s|%s" % [tex.resource_path, tex.get_size()]
	if tex.resource_path.contains("router walk"):
		key = "walk|%s" % tex.get_size()
	if _body_cache.has(key):
		return _body_cache[key]
	var ts = tex.get_size()
	var r = Rect2(FALLBACK_BODY.position * ts, FALLBACK_BODY.size * ts)
	var img = tex.get_image()
	if img:
		var used = img.get_used_rect()
		if used.size.x > 0:
			r = Rect2(used)
	_body_cache[key] = r
	return r

func _process(_delta: float) -> void:
	if visible:
		_update_placement()

func _update_placement() -> void:
	if sprite == null or not is_instance_valid(sprite) or sprite.texture == null or acc_rect == null or acc_rect.texture == null:
		return
	var p: Dictionary = PLACEMENT.get(acc_id, PLACEMENT["helmet"])
	var tex = sprite.texture
	var ts = tex.get_size()
	var sz = sprite.size
	var sc = Vector2.ONE
	var origin = Vector2.ZERO
	if sprite.stretch_mode == TextureRect.STRETCH_SCALE:
		sc = Vector2(sz.x / ts.x, sz.y / ts.y)
	else:
		var s = min(sz.x / ts.x, sz.y / ts.y)
		sc = Vector2(s, s)
		origin = (sz - ts * s) / 2.0
	var body = _body_rect(tex)
	var b_pos = origin + body.position * sc
	var b_size = body.size * sc
	var at_size = acc_rect.texture.get_size()
	var w = b_size.x * float(p["w"])
	var h = w * at_size.y / at_size.x
	var u = float(p["u"])
	if sprite.flip_h:
		u = 1.0 - u
	var center = Vector2(b_pos.x + b_size.x * u, b_pos.y + b_size.y * float(p["v"]))
	acc_rect.size = Vector2(w, h)
	acc_rect.position = center - Vector2(w, h) / 2.0
	acc_rect.flip_h = sprite.flip_h
