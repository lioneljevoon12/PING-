extends Control

signal closed

@onready var dim_backdrop: ColorRect = %DimBackdrop
@onready var book_wrapper: Control = %BookWrapper
@onready var close_btn: CloseButton = %CloseButton
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
	},
	{
		"left": {
			"title": "APA ITU JARINGAN KOMPUTER?",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Definisi Singkat:[/color][/b]\nJaringan komputer adalah kumpulan perangkat (komputer, ponsel, printer, server) yang saling terhubung agar bisa [b]bertukar data[/b] dan [b]berbagi sumber daya[/b].\n\n[b][color=#166534]Manfaat Jaringan:[/color][/b]\n• Berbagi file, printer, dan koneksi internet\n• Komunikasi cepat (surel, pesan, panggilan video)\n• Data terpusat sehingga mudah dicadangkan\n• Menghemat biaya perangkat dan perawatan\n\n[i][color=#4b5563]💡 Setiap hari kamu memakai jaringan: membuka video, bermain gim daring, hingga membayar lewat QRIS.[/color][/i]"
		},
		"right": {
			"title": "ISTILAH DASAR",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#1e3a8a]Kata yang Sering Muncul:[/color][/b]\n• [b]Host / Node:[/b] perangkat apa pun yang terhubung ke jaringan\n• [b]Client:[/b] perangkat yang meminta layanan\n• [b]Server:[/b] perangkat yang menyediakan layanan\n• [b]Protokol:[/b] aturan bersama agar perangkat saling paham\n• [b]Paket:[/b] potongan kecil data yang dikirim lewat jaringan\n• [b]Topologi:[/b] bentuk susunan hubungan antar perangkat\n\n[i][color=#4b5563]💡 Analogi: server seperti dapur restoran, client seperti pelanggan, protokol seperti bahasa yang disepakati.[/color][/i]"
		}
	},
	{
		"left": {
			"title": "SATUAN DATA & KECEPATAN",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Bit dan Byte:[/color][/b]\n• 1 Byte = 8 bit\n• 1 KB = 1.024 Byte\n• 1 MB = 1.024 KB\n• 1 GB = 1.024 MB\n\n[b][color=#b45309]Kecepatan Jaringan:[/color][/b]\n• Kecepatan jaringan ditulis dalam [b]bit[/b] per detik (bps, Kbps, Mbps, Gbps)\n• Ukuran file ditulis dalam [b]Byte[/b] (KB, MB, GB)\n• Unduhan 8 Mbps kira-kira ± 1 MB per detik\n\n[i][color=#4b5563]💡 Karena itu paket internet 100 Mbps tidak mengunduh 100 MB dalam 1 detik.[/color][/i]"
		},
		"right": {
			"title": "BANDWIDTH, LATENCY, THROUGHPUT",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#166534]Tiga Ukuran Mutu Jaringan:[/color][/b]\n• [b]Bandwidth:[/b] kapasitas maksimum jalur, seperti lebar jalan raya\n• [b]Throughput:[/b] kecepatan nyata yang berhasil lewat saat ini\n• [b]Latency:[/b] waktu tunda perjalanan data (satuan milidetik, ms)\n• [b]Packet loss:[/b] persentase paket yang hilang di jalan\n\n[b][color=#6d28d9]Contoh Rasa:[/color][/b]\n• Video streaming butuh bandwidth besar\n• Gim daring butuh latency rendah\n• Panggilan suara tidak suka paket yang hilang\n\n[i][color=#4b5563]💡 Jalan lebar belum tentu lancar: bisa saja macet sehingga throughput turun.[/color][/i]"
		}
	},
	{
		"left": {
			"title": "MEDIA TRANSMISI",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Jalur Pembawa Data:[/color][/b]\n• [b]Kabel UTP/STP:[/b] pasangan tembaga berpilin, murah dan umum di kantor\n• [b]Kabel Koaksial:[/b] dipakai untuk TV kabel dan sebagian internet rumah\n• [b]Serat Optik (Fiber):[/b] mengirim cahaya, cepat dan jauh, kebal gangguan listrik\n• [b]Nirkabel (Wi-Fi):[/b] gelombang radio, praktis tetapi lebih mudah terganggu\n\n[b][color=#b45309]Kategori Kabel UTP:[/color][/b]\n• Cat5e: umum untuk 1 Gbps\n• Cat6: lebih stabil untuk jarak dekat berkecepatan tinggi\n• Panjang maksimum segmen UTP ± 100 meter"
		},
		"right": {
			"title": "KAPAN PAKAI APA?",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#166534]Memilih Media:[/color][/b]\n• Ruang kantor dan kelas: kabel UTP ke tiap meja\n• Antar gedung berjauhan: serat optik\n• Perangkat seluler: Wi-Fi atau data seluler\n• Area ramai gangguan listrik: kabel STP atau fiber\n\n[b][color=#6d28d9]Hal yang Perlu Diingat:[/color][/b]\n• Kabel yang ditekuk tajam bisa merusak kawat di dalamnya\n• Konektor longgar adalah penyebab gangguan yang sangat sering\n• Beri label kabel agar mudah ditelusuri\n\n[i][color=#4b5563]💡 Banyak masalah jaringan ternyata sederhana: kabel kendur atau salah colok.[/color][/i]"
		}
	},
	{
		"left": {
			"title": "PERANGKAT JARINGAN LAIN",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Peran Perangkat:[/color][/b]\n• [b]NIC (Network Interface Card):[/b] kartu jaringan di tiap perangkat, tempat colokan kabel atau antena Wi-Fi\n• [b]Modem:[/b] menghubungkan jaringanmu ke penyedia internet (ISP)\n• [b]Router:[/b] menghubungkan beberapa jaringan dan menentukan jalur keluar-masuk\n• [b]Access Point:[/b] memancarkan sinyal Wi-Fi agar perangkat nirkabel bisa bergabung\n• [b]Repeater:[/b] menguatkan sinyal agar jangkauan lebih jauh\n• [b]Firewall:[/b] penyaring lalu lintas berdasarkan aturan keamanan"
		},
		"right": {
			"title": "PERANGKAT DI RUMAH",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#166534]Router Wi-Fi Rumahan:[/color][/b]\nBiasanya satu kotak berisi beberapa fungsi sekaligus:\n• Router untuk mengatur lalu lintas\n• Access point untuk Wi-Fi\n• Beberapa colokan kabel untuk perangkat berkabel\n• Pengaman dasar (firewall sederhana)\n\n[b][color=#b45309]Membaca Lampu Indikator:[/color][/b]\n• Lampu hidup stabil: biasanya tersambung\n• Lampu berkedip: ada aliran data\n• Lampu mati: periksa kabel dan sumber daya\n\n[i][color=#4b5563]💡 Saat internet bermasalah, mulai dari yang paling mudah: kabel, lampu, lalu mulai ulang perangkat.[/color][/i]"
		}
	},
	{
		"left": {
			"title": "MAC ADDRESS & IP ADDRESS",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Dua Jenis Alamat:[/color][/b]\n• [b]MAC Address:[/b] alamat fisik 48-bit yang tertanam di NIC, ditulis heksadesimal, mis. 00:1A:2B:3C:4D:5E\n• [b]IP Address:[/b] alamat logis yang diberikan untuk jaringan dan bisa berubah\n\n[b][color=#166534]Perbedaan Cara Pandang:[/color][/b]\n• MAC seperti nomor rangka kendaraan\n• IP seperti alamat rumah tempat kamu tinggal\n• MAC dipakai dalam satu jaringan lokal, IP dipakai untuk menjangkau jaringan lain\n\n[i][color=#4b5563]💡 Ponsel yang pindah dari rumah ke kafe biasanya ganti IP, tetapi MAC-nya tetap.[/color][/i]"
		},
		"right": {
			"title": "ANATOMI ALAMAT IPv4",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#1e3a8a]Membaca Sebuah IPv4:[/color][/b]\n• Terdiri dari 4 bagian (oktet) dipisah titik, mis. 192.168.1.10\n• Tiap oktet bernilai 0 sampai 255 (8 bit)\n• Total 32 bit\n\n[b][color=#b45309]Subnet Mask:[/color][/b]\n• Menandai bagian mana dari alamat yang menunjukkan jaringan dan bagian mana menunjukkan perangkat\n• Dapat ditulis 255.255.255.0 atau notasi /24\n\n[b][color=#6d28d9]Alamat Khusus:[/color][/b]\n• 127.0.0.1 : loopback (alamat perangkat sendiri)\n• 169.254.x.x : alamat otomatis saat gagal mendapat IP\n\n[i][color=#4b5563]💡 Hitung dalam biner membantu memahami batas jaringan.[/color][/i]"
		}
	},
	{
		"left": {
			"title": "DNS & DHCP (KONSEP)",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]DNS - Buku Telepon Internet:[/color][/b]\n• Manusia mudah mengingat nama (mis. situs.com), komputer memakai angka IP\n• DNS menerjemahkan nama domain menjadi alamat IP\n• Tanpa DNS kamu harus menghafal deretan angka\n\n[b][color=#166534]DHCP - Pembagi Alamat Otomatis:[/color][/b]\n• Memberi IP, subnet mask, dan gateway ke perangkat yang baru terhubung\n• Menghindari bentrok alamat karena dua perangkat memakai IP sama\n• Alamat bisa disewa untuk jangka waktu tertentu (lease)\n\n[i][color=#4b5563]💡 Gateway adalah 'pintu keluar' menuju jaringan lain, umumnya router.[/color][/i]"
		},
		"right": {
			"title": "IPv6 SEKILAS",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#1e3a8a]Mengapa IPv6?[/color][/b]\nIPv4 hanya punya sekitar 4,3 miliar alamat, sementara perangkat terus bertambah.\n\n[b][color=#166534]Ciri IPv6:[/color][/b]\n• Panjang 128 bit, ditulis heksadesimal\n• Contoh: 2001:0db8:85a3:0000:0000:8a2e:0370:7334\n• Deretan nol berurutan boleh dipersingkat dengan ::\n• Jumlah alamat nyaris tak terbatas\n\n[b][color=#b45309]Hidup Berdampingan:[/color][/b]\nIPv4 dan IPv6 dipakai bersamaan selama masa peralihan (dual stack)."
		}
	},
	{
		"left": {
			"title": "ALAT BANTU TROUBLESHOOTING",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#1e3a8a]Perintah Dasar Teknisi:[/color][/b]\n• [b]ping:[/b] menguji apakah perangkat lain bisa dijangkau dan berapa lama balasannya\n• [b]ipconfig / ifconfig:[/b] melihat IP, mask, dan gateway milik perangkatmu\n• [b]tracert / traceroute:[/b] menelusuri jalur menuju tujuan\n• [b]nslookup:[/b] menguji penerjemahan nama domain\n\n[b][color=#b45309]Urutan Berpikir:[/color][/b]\n1. Apakah kabel/Wi-Fi tersambung?\n2. Apakah perangkat punya alamat yang wajar?\n3. Apakah gateway bisa dijangkau?\n4. Apakah nama domain bisa diterjemahkan?\n\n[i][color=#4b5563]💡 Mulai dari lapisan paling bawah, naik pelan-pelan.[/color][/i]"
		},
		"right": {
			"title": "KESELAMATAN & ETIKA TEKNISI",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#166534]Bekerja dengan Aman:[/color][/b]\n• Matikan daya sebelum menyentuh perangkat yang terbuka\n• Rapikan kabel agar tidak menjadi jebakan tersandung\n• Gunakan alat sesuai fungsinya (tang crimping, tester kabel)\n\n[b][color=#6d28d9]Bekerja dengan Rapi:[/color][/b]\n• Beri label pada kabel dan port\n• Catat perubahan konfigurasi\n• Simpan dokumentasi denah jaringan\n\n[b][color=#991b1b]Etika:[/color][/b]\n• Jangan mengakses data atau perangkat tanpa izin\n• Rahasiakan kata sandi yang kamu ketahui"
		}
	},
	{
		"left": {
			"title": "KEAMANAN JARINGAN DASAR",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#991b1b]Ancaman Umum:[/color][/b]\n• [b]Phishing:[/b] pesan palsu yang memancing kamu memberikan data\n• [b]Malware:[/b] program berbahaya (virus, ransomware, spyware)\n• [b]Penyadapan:[/b] membaca data yang dikirim tanpa enkripsi\n• [b]Kata sandi lemah:[/b] mudah ditebak penyerang\n\n[b][color=#166534]Kebiasaan Baik:[/color][/b]\n• Kata sandi panjang dan unik, aktifkan verifikasi dua langkah\n• Perbarui sistem dan aplikasi secara rutin\n• Waspada Wi-Fi publik tanpa kata sandi\n• Cadangkan data penting\n\n[i][color=#4b5563]💡 Pengamanan terbaik adalah kebiasaan, bukan satu alat saja.[/color][/i]"
		},
		"right": {
			"title": "ENKRIPSI, VPN, & FIREWALL",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#1e3a8a]Konsep Perlindungan:[/color][/b]\n• [b]Enkripsi:[/b] mengacak data sehingga hanya penerima berhak yang bisa membacanya\n• [b]VPN:[/b] terowongan terenkripsi lewat jaringan umum\n• [b]Firewall:[/b] penjaga gerbang yang mengikuti aturan izinkan atau tolak\n• [b]Autentikasi:[/b] membuktikan identitas (kata sandi, sidik jari, token)\n\n[b][color=#b45309]Lapisan Pertahanan:[/color][/b]\nKeamanan dibangun berlapis: perangkat, jaringan, aplikasi, dan manusia. Jika satu lapis bocor, lapis lain masih menahan."
		}
	},
	{
		"left": {
			"title": "KAMUS MINI (A-M)",
			"image": null,
			"image_height": 0,
			"desc": "• [b]ACK:[/b] tanda balasan bahwa data diterima\n• [b]Bandwidth:[/b] kapasitas jalur\n• [b]Broadcast:[/b] pesan untuk semua perangkat di satu jaringan\n• [b]Cache:[/b] tempat simpan sementara agar akses lebih cepat\n• [b]Domain:[/b] nama situs yang mudah diingat\n• [b]Enkripsi:[/b] pengacakan data demi keamanan\n• [b]Frame:[/b] unit data pada lapisan penghubung data\n• [b]Gateway:[/b] pintu menuju jaringan lain\n• [b]Host:[/b] perangkat yang terhubung\n• [b]ISP:[/b] penyedia layanan internet\n• [b]Latency:[/b] waktu tunda\n• [b]MAC:[/b] alamat fisik perangkat"
		},
		"right": {
			"title": "KAMUS MINI (N-Z)",
			"image": null,
			"image_height": 0,
			"body": "• [b]NAT:[/b] penerjemah alamat privat ke publik\n• [b]Node:[/b] titik pada jaringan\n• [b]Packet:[/b] paket data\n• [b]Ping:[/b] uji jangkauan perangkat\n• [b]Protokol:[/b] aturan komunikasi\n• [b]Router:[/b] penghubung antar jaringan\n• [b]SSID:[/b] nama jaringan Wi-Fi\n• [b]Subnet:[/b] pecahan dari satu jaringan besar\n• [b]Switch:[/b] penghubung perangkat dalam satu jaringan\n• [b]Throughput:[/b] kecepatan nyata\n• [b]Unicast:[/b] pesan untuk satu tujuan tertentu\n• [b]VPN:[/b] terowongan terenkripsi\n• [b]WAN:[/b] jaringan area luas"
		}
	},
	{
		"left": {
			"title": "TIPS BERMAIN PING!",
			"image": null,
			"image_height": 0,
			"desc": "[b][color=#166534]Strategi Menyelesaikan Level:[/color][/b]\n• Baca pop up pembuka dengan teliti, itu petunjuk tugasnya\n• Tekan tombol [b]?[/b] kuning kapan saja untuk melihat panduan level\n• Perhatikan label, warna, dan angka pada objek\n• Tiga hati adalah nyawamu, jadi jangan menebak asal\n• Waktu terus berjalan, tetapi ketelitian lebih utama\n\n[b][color=#b45309]Jika Buntu:[/color][/b]\n• Buka kembali buku panduan ini\n• Coba gunakan Mode Latihan tanpa batas waktu\n• Ulangi level, mengulang adalah cara belajar\n\n[i][color=#4b5563]💡 Bintang bergantung pada sisa nyawa, jadi teliti kunci bintang tiga.[/color][/i]"
		},
		"right": {
			"title": "MENGAPA BELAJAR JARINGAN?",
			"image": null,
			"image_height": 0,
			"body": "[b][color=#1e3a8a]Peluang Karier:[/color][/b]\n• Teknisi jaringan dan helpdesk\n• Administrator sistem\n• Insinyur jaringan\n• Analis keamanan siber\n• Teknisi komputasi awan (cloud)\n\n[b][color=#166534]Keterampilan yang Berguna:[/color][/b]\n• Berpikir runtut saat mencari sumber masalah\n• Teliti membaca angka dan konfigurasi\n• Terbiasa membuat dokumentasi\n• Komunikasi yang jelas dengan pengguna\n\n[i][color=#4b5563]💡 Sertifikasi seperti CCNA dan Network+ sering menjadi langkah lanjutan bagi yang tertarik.[/color][/i]"
		}
	}
]

func _ready() -> void:
	visible = false
	book_wrapper.pivot_offset = book_wrapper.size / 2.0
	
	close_btn.pivot_offset = close_btn.size / 2.0
	prev_btn.pivot_offset = prev_btn.size / 2.0
	next_btn.pivot_offset = next_btn.size / 2.0
	
	close_btn.closed.connect(close)
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
	
	if get_parent() == get_tree().root:
		open(0)
		closed.connect(func(): get_tree().change_scene_to_file("res://scenes/learn_screen.tscn"))
	
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
