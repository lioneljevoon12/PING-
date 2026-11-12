extends Node

signal user_changed(username: String)
signal customization_changed

var current_username: String = "Teknisi"
var is_logged_in: bool = false
var current_stage: int = 1
var unlocked_stage: int = 5

# Customization state (Dummy / Persistent)
var current_skin: String = "classic"
var current_accessory: String = "none"
var current_title: String = "Junior Technician"

const SKIN_CONFIG: Dictionary = {
	"classic": { "name": "Classic Teal", "color": Color("#38bdf8"), "desc": "Warna asli maskot router PING!" },
	"neon": { "name": "Cyber Neon", "color": Color("#c084fc"), "desc": "Nuansa futuristik ungu cyber" },
	"gold": { "name": "Golden Master", "color": Color("#facc15"), "desc": "Warna emas teknisi senior legendaris" },
	"sakura": { "name": "Pastel Sakura", "color": Color("#f472b6"), "desc": "Merah muda lembut estetis" },
	"retro": { "name": "Retro Cisco", "color": Color("#94a3b8"), "desc": "Gaya abu-abu vintage era 90-an" },
	"mint": { "name": "Emerald Mint", "color": Color("#4ade80"), "desc": "Hijau segar spesialis kabel LAN" }
}

const ACCESSORY_CONFIG: Dictionary = {
	"none": { "name": "Tanpa Aksesoris", "icon": "❌" },
	"helmet": { "name": "Helm Proyek", "icon": "👷" },
	"visor": { "name": "Kacamata AR Cyber", "icon": "🥽" },
	"headset": { "name": "Headset Admin", "icon": "🎧" },
	"grad_cap": { "name": "Topi Sarjana", "icon": "🎓" }
}

const TITLE_OPTIONS: Array[String] = [
	"Junior Technician",
	"Cable Craftsman",
	"Packet Whisperer",
	"Subnet Specialist",
	"Firewall Guardian",
	"Master Network Architect"
]

const SAVE_PATH: String = "user://player_progress.json"

# Progression: Stage 1.1 Unlocked initially, others locked
var stage_progress: Dictionary = {
	1: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
	2: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
	3: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0, 4: 0 } },
	4: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
	5: { "unlocked_level": 1, "stars": { 1: 0, 2: 0, 3: 0 } },
}

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	load_progress()

# --- UNLOCK & PROGRESSION SYSTEM ---

# Variabel konfigurasi mode testing: semua stage & level terbuka untuk mempermudah testing
var test_mode_all_unlocked: bool = true

func is_stage_unlocked(stage_num: int) -> bool:
	if test_mode_all_unlocked:
		return true
	return stage_num <= unlocked_stage

func is_level_unlocked(stage_num: int, level_num: int) -> bool:
	if test_mode_all_unlocked:
		return true
	if not is_stage_unlocked(stage_num):
		return false
	if level_num == 1:
		return true
	return level_num <= get_stage_unlocked_level(stage_num)

func get_stage_unlocked_level(stage_num: int) -> int:
	if test_mode_all_unlocked:
		return 4 if stage_num == 3 else 3
	if stage_num in stage_progress:
		return int(stage_progress[stage_num].get("unlocked_level", 1))
	return 1

func get_level_stars(stage_num: int, level_num: int) -> int:
	if stage_num in stage_progress and "stars" in stage_progress[stage_num]:
		return int(stage_progress[stage_num]["stars"].get(level_num, 0))
	return 0

func set_level_stars(stage_num: int, level_num: int, stars: int) -> void:
	if stage_num not in stage_progress:
		stage_progress[stage_num] = { "unlocked_level": 1, "stars": {} }
		
	var prev_stars = int(stage_progress[stage_num]["stars"].get(level_num, 0))
	stage_progress[stage_num]["stars"][level_num] = max(prev_stars, stars)
	
	var max_stage_level = 4 if stage_num == 3 else 3
	if stars > 0:
		if level_num < max_stage_level:
			var next_lvl = level_num + 1
			var cur_unlocked = int(stage_progress[stage_num].get("unlocked_level", 1))
			stage_progress[stage_num]["unlocked_level"] = max(cur_unlocked, next_lvl)
		elif level_num == max_stage_level:
			# Tamat stage ini -> Buka stage berikutnya!
			unlocked_stage = max(unlocked_stage, stage_num + 1)
			if (stage_num + 1) in stage_progress:
				var next_stage_lvl = int(stage_progress[stage_num + 1].get("unlocked_level", 1))
				stage_progress[stage_num + 1]["unlocked_level"] = max(next_stage_lvl, 1)
				
	save_progress()

func get_stage_stars(stage_num: int) -> int:
	var total = 0
	if stage_num in stage_progress and "stars" in stage_progress[stage_num]:
		for s in stage_progress[stage_num]["stars"].values():
			total += int(s)
	return total

func get_stage_cleared_count(stage_num: int) -> int:
	var count = 0
	if stage_num in stage_progress and "stars" in stage_progress[stage_num]:
		for s in stage_progress[stage_num]["stars"].values():
			if int(s) > 0:
				count += 1
	return count

func get_total_stars() -> int:
	var total = 0
	for stage in stage_progress.values():
		if "stars" in stage:
			for s in stage["stars"].values():
				total += int(s)
	return total

func get_max_stars() -> int:
	return 48 # (4 Stage x 3 Level + 1 Stage x 4 Level) x 3 Bintang = 48 Bintang

# --- CUSTOMIZATION SYSTEM ---

func get_active_skin_color() -> Color:
	if current_skin in SKIN_CONFIG:
		return SKIN_CONFIG[current_skin]["color"]
	return Color("#38bdf8")

func set_customization(skin: String, accessory: String, title_name: String) -> void:
	current_skin = skin
	current_accessory = accessory
	current_title = title_name
	save_progress()
	customization_changed.emit()

# --- SAVE & LOAD SYSTEM ---

func save_progress() -> void:
	var stage_data: Dictionary = {}
	for s_num in stage_progress.keys():
		var stars_dict: Dictionary = {}
		for lvl in stage_progress[s_num]["stars"].keys():
			stars_dict[str(lvl)] = int(stage_progress[s_num]["stars"][lvl])
		stage_data[str(s_num)] = {
			"unlocked_level": int(stage_progress[s_num]["unlocked_level"]),
			"stars": stars_dict
		}
		
	var payload: Dictionary = {
		"username": current_username,
		"unlocked_stage": unlocked_stage,
		"current_skin": current_skin,
		"current_accessory": current_accessory,
		"current_title": current_title,
		"stage_progress": stage_data
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
		
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if not parsed or typeof(parsed) != TYPE_DICTIONARY:
		return
		
	current_username = parsed.get("username", current_username)
	unlocked_stage = int(parsed.get("unlocked_stage", 1))
	current_skin = parsed.get("current_skin", "classic")
	current_accessory = parsed.get("current_accessory", "none")
	current_title = parsed.get("current_title", "Junior Technician")
	
	var saved_sp = parsed.get("stage_progress", {})
	if typeof(saved_sp) == TYPE_DICTIONARY:
		for s_str in saved_sp.keys():
			var s_int = int(s_str)
			if s_int in stage_progress:
				var s_obj = saved_sp[s_str]
				stage_progress[s_int]["unlocked_level"] = int(s_obj.get("unlocked_level", 1))
				var stars_obj = s_obj.get("stars", {})
				for lvl_str in stars_obj.keys():
					var lvl_int = int(lvl_str)
					stage_progress[s_int]["stars"][lvl_int] = int(stars_obj[lvl_str])

# --- RESET / DEV UTILITIES ---

func reset_progress_to_default() -> void:
	unlocked_stage = 1
	for s_num in range(1, 6):
		var num_lvls = 4 if s_num == 3 else 3
		var stars_dict: Dictionary = {}
		for l in range(1, num_lvls + 1):
			stars_dict[l] = 0
		stage_progress[s_num] = {
			"unlocked_level": 1,
			"stars": stars_dict
		}
	save_progress()

func unlock_all_levels() -> void:
	unlocked_stage = 5
	for s_num in range(1, 6):
		var num_lvls = 4 if s_num == 3 else 3
		var stars_dict: Dictionary = {}
		for l in range(1, num_lvls + 1):
			stars_dict[l] = 3
		stage_progress[s_num] = {
			"unlocked_level": num_lvls,
			"stars": stars_dict
		}
	save_progress()

# --- USER SESSIONS ---

func login(user: String) -> void:
	if user.strip_edges() != "":
		current_username = user.strip_edges()
	else:
		current_username = "Teknisi"
	is_logged_in = true
	save_progress()
	user_changed.emit(current_username)

func logout() -> void:
	current_username = "Tamu"
	is_logged_in = false
	user_changed.emit(current_username)
