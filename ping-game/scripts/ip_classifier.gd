class_name IPClassifier
extends RefCounted

# Logika murni klasifikasi alamat IPv4 (Classful Addressing)
# Bebas dari dependensi node UI atau rendering.

const CLASS_A_MIN = 1
const CLASS_A_MAX = 126

const CLASS_B_MIN = 128
const CLASS_B_MAX = 191

const CLASS_C_MIN = 192
const CLASS_C_MAX = 223

## Mendapatkan kelas IP ("A", "B", "C") dari nilai oktet pertama.
## Mengembalikan string kosong "" jika di luar rentang A, B, atau C (misal 0, 127, >= 224).
static func get_class_from_octet(octet: int) -> String:
	if octet >= CLASS_A_MIN and octet <= CLASS_A_MAX:
		return "A"
	elif octet >= CLASS_B_MIN and octet <= CLASS_B_MAX:
		return "B"
	elif octet >= CLASS_C_MIN and octet <= CLASS_C_MAX:
		return "C"
	return ""

## Mendapatkan kelas IP dari string IP lengkap (contoh "192.168.1.10" -> "C").
static func get_class_from_ip(ip: String) -> String:
	var parts = ip.split(".")
	if parts.size() > 0 and parts[0].is_valid_int():
		return get_class_from_octet(parts[0].to_int())
	return ""

## Mengecek apakah oktet pertama valid untuk klasifikasi A, B, C.
static func is_valid_first_octet(octet: int) -> bool:
	return get_class_from_octet(octet) != ""

## Menghasilkan oktet pertama acak untuk kelas yang diinginkan ("A", "B", atau "C").
## Menghindari mutlak nilai 0, 127, dan >= 224.
static func generate_first_octet(target_class: String) -> int:
	match target_class.to_upper():
		"A":
			return randi_range(CLASS_A_MIN, CLASS_A_MAX)
		"B":
			return randi_range(CLASS_B_MIN, CLASS_B_MAX)
		"C":
			return randi_range(CLASS_C_MIN, CLASS_C_MAX)
		_:
			# Jika tidak ditentukan, acak salah satu kelas
			var classes = ["A", "B", "C"]
			return generate_first_octet(classes[randi() % classes.size()])

## Menghasilkan data paket lengkap dengan IP valid:
## { "ip": String, "first_octet": int, "rest": String, "class": String, "hint": String }
static func generate_packet_data(forced_class: String = "") -> Dictionary:
	var cls = forced_class.to_upper()
	if cls not in ["A", "B", "C"]:
		var classes = ["A", "B", "C"]
		cls = classes[randi() % classes.size()]
		
	var oct1 = generate_first_octet(cls)
	var oct2 = randi_range(0, 255)
	var oct3 = randi_range(0, 255)
	var oct4 = randi_range(1, 254)
	
	var rest_str = ".%d.%d.%d" % [oct2, oct3, oct4]
	var full_ip = "%d%s" % [oct1, rest_str]
	var hint = get_educational_hint(oct1, cls)
	
	return {
		"first_octet": oct1,
		"rest": rest_str,
		"ip": full_ip,
		"class": cls,
		"hint": hint
	}

## Menghasilkan penjelasan singkat edukatif untuk oktet tertentu
static func get_educational_hint(octet: int, actual_class: String = "") -> String:
	var cls = actual_class
	if cls == "":
		cls = get_class_from_octet(octet)
		
	match cls:
		"A":
			return "Oktet pertama %d berada di rentang 1-126, jadi termasuk Kelas A!" % octet
		"B":
			return "Oktet pertama %d berada di rentang 128-191, jadi termasuk Kelas B!" % octet
		"C":
			return "Oktet pertama %d berada di rentang 192-223, jadi termasuk Kelas C!" % octet
		_:
			if octet == 127:
				return "Oktet 127 adalah Loopback Address, bukan Kelas A/B/C!"
			elif octet == 0:
				return "Oktet 0 adalah Default/Network Address khusus!"
			elif octet >= 224 and octet <= 239:
				return "Oktet %d termasuk Kelas D (Multicast)!" % octet
			else:
				return "Oktet %d termasuk Kelas E (Eksperimental)!" % octet

## Mendapatkan teks rentang oktet pertama per kelas
static func get_range_text(cls: String) -> String:
	match cls.to_upper():
		"A":
			return "1 - 126"
		"B":
			return "128 - 191"
		"C":
			return "192 - 223"
		_:
			return ""

## Mendapatkan contoh IP representatif per kelas
static func get_example_ip(cls: String) -> String:
	match cls.to_upper():
		"A":
			return "10.24.1.5"
		"B":
			return "172.16.0.4"
		"C":
			return "192.168.1.10"
		_:
			return ""


# ==============================================================================
# LOGIKA FIREWALL MANUAL (LEVEL 2.2): IP PRIVAT (RFC 1918) VS IP PUBLIK
# ==============================================================================

## Mengecek apakah sebuah IP merupakan IP Privat (RFC 1918):
## 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
## 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
## 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)
static func is_private_ip(ip: String) -> bool:
	var parts = ip.split(".")
	if parts.size() < 4:
		return false
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return false
	var o1 = parts[0].to_int()
	var o2 = parts[1].to_int()
	
	if o1 == 10:
		return true
	if o1 == 172 and o2 >= 16 and o2 <= 31:
		return true
	if o1 == 192 and o2 == 168:
		return true
	return false

## Aksi firewall: "ALLOW" (Izinkan IP Privat) atau "BLOCK" (Blokir IP Publik)
static func get_firewall_action(ip: String) -> String:
	return "ALLOW" if is_private_ip(ip) else "BLOCK"

## Mendapatkan penjelasan edukatif firewall untuk IP tertentu
static func get_firewall_hint(ip: String) -> String:
	var parts = ip.split(".")
	if parts.size() < 4:
		return "Format alamat IP tidak valid!"
	var o1 = parts[0].to_int()
	var o2 = parts[1].to_int()
	
	if o1 == 10:
		return "%s adalah IP Privat rentang 10.0.0.0/8 (10.x.x.x). Trafik internal sah -> ALLOW!" % ip
	elif o1 == 172 and o2 >= 16 and o2 <= 31:
		return "%s adalah IP Privat rentang 172.16.0.0/12 (172.16-31.x.x). Trafik internal sah -> ALLOW!" % ip
	elif o1 == 192 and o2 == 168:
		return "%s adalah IP Privat rentang 192.168.0.0/16 (192.168.x.x). Trafik internal sah -> ALLOW!" % ip
	else:
		return "%s adalah IP Publik (WAN eksternal) di luar rentang IP Privat RFC 1918. Akses langsung diblokir -> BLOCK!" % ip

## Menghasilkan paket data firewall tunggal
static func generate_firewall_packet(force_action: String = "") -> Dictionary:
	var action = force_action.to_upper()
	if action not in ["ALLOW", "BLOCK"]:
		action = "ALLOW" if (randi() % 2 == 0) else "BLOCK"
		
	var o1: int = 192
	var o2: int = 168
	var o3: int = randi_range(0, 255)
	var o4: int = randi_range(1, 254)
	
	if action == "ALLOW":
		var pick = randi() % 3
		if pick == 0:
			o1 = 10
			o2 = randi_range(0, 255)
		elif pick == 1:
			o1 = 172
			o2 = randi_range(16, 31)
		else:
			o1 = 192
			o2 = 168
	else:
		var public_presets = [
			Vector2i(203, 0),
			Vector2i(8, 8),
			Vector2i(185, 199),
			Vector2i(93, 184),
			Vector2i(142, 250),
			Vector2i(198, 51),
			Vector2i(172, 32),
			Vector2i(192, 169),
			Vector2i(11, 24)
		]
		var preset = public_presets[randi() % public_presets.size()]
		o1 = preset.x
		o2 = preset.y
		
	var full_ip = "%d.%d.%d.%d" % [o1, o2, o3, o4]
	var rest_str = ".%d.%d.%d" % [o2, o3, o4]
	
	return {
		"first_octet": o1,
		"rest": rest_str,
		"ip": full_ip,
		"action": action,
		"is_private": (action == "ALLOW"),
		"hint": get_firewall_hint(full_ip)
	}

## Menghasilkan tumpukan paket berimbang (default 6 paket: 3 Allow, 3 Block)
static func generate_firewall_deck(count: int = 6) -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	var half = int(count / 2)
	for i in range(half):
		deck.append(generate_firewall_packet("ALLOW"))
	for i in range(count - half):
		deck.append(generate_firewall_packet("BLOCK"))
	deck.shuffle()
	return deck
