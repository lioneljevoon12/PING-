# 🌐 PING! — Cozy Network Simulation & Logic Puzzle Game

<p align="center">
  <img src="ping-game/art/assets/PING!%20Assets/Titles/PING-JUDUL.png" alt="PING! Logo" width="380"/>
</p>

<p align="center">
  <b>Game edukasi interaktif 2D bertema jaringan komputer dengan visual <i>cozy kawaii doodle</i>, mekanika <i>time-attack logic puzzle</i>, dan simulasi jaringan berstandar kurikulum IT.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Engine-Godot%204.x-478cbf?logo=godotengine&logoColor=white" alt="Godot 4"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows-brightgreen" alt="Platform"/>
  <img src="https://img.shields.io/badge/Genre-Simulation%20%7C%20Puzzle%20%7C%20Educational-orange" alt="Genre"/>
  <img src="https://img.shields.io/badge/SDGs-Goal%204%3A%20Quality%20Education-blue" alt="SDGs"/>
</p>

---

## 📖 1. Tentang Game PING!

Nama **PING!** diambil dari utilitas *command-line* legendaris dalam dunia jaringan komputer (*Packet Internet Groper* / penguji jangkauan koneksi antar host). Nama ini merepresentasikan misi utama game: **menghubungkan konsep jaringan komputer yang rumit dan abstrak menjadi pemahaman yang konkret, interaktif, dan ramah bagi pemain pemula.**

### Latar Belakang & Motivasi (SDGs Goal 4)
Mempelajari dasar infrastruktur jaringan komputer (seperti pengkabelan UTP, subnetting, model OSI, dan IP routing) sering dianggap kaku, mengintimidasi, dan sarat beban kognitif (*cognitive overload*), terutama bagi siswa pemula atau mahasiswa IT tingkat awal yang dihadapkan langsung dengan simulator profesional seperti Cisco Packet Tracer atau GNS3.

**PING!** hadir untuk memecahkan *barrier of entry* tersebut dengan mengusung semangat **Sustainable Development Goals (SDGs) Target ke-4: Pendidikan Berkualitas**:
* Mengubah materi teknis yang kaku menjadi game teka-teki logika yang estetik, hangat (*cozy pastel*), dan ramah mata.
* Menggunakan metode **"Personifikasi Data & Perangkat"** — di mana paket data digambarkan sebagai amplop bersayap imut dan perangkat keras (router, switch, kabel) memiliki ekspresi wajah responsif.

---

## 🎮 2. Sinopsis & Alur Cerita (Lore)

Pemain berperan sebagai seorang **Teknisi Jaringan Muda** yang baru saja diterima bekerja di kantor IT modern yang asri dan estetik. Alih-alih ruang server bawah tanah yang gelap, dingin, dan menegangkan, ruang kerja dihiasi pot tanaman, meja kerja kayu, dan nuansa pastel yang hangat.

Namun, ketenangan tersebut diuji setiap hari oleh krisis infrastruktur jaringan:
* Kabel UTP putus dan tercampur aduk.
* Susunan pin konektor RJ45 yang salah pasang.
* Router yang kepanasan (*overheat*) dan tertidur.
* Paket data yang kebingungan mencari alamat IP tujuan.

Tugas pemain adalah menjadi **Sole Troubleshooter**: berkeliling ruangan, mengidentifikasi kerusakan, menyelesaikan teka-teki perbaikan sebelum batas waktu (*timer*) habis, dan menyelamatkan perusahaan dari ancaman *total network downtime*!

---

## 🕹️ 3. Mekanika & Fitur Utama

| Fitur | Deskripsi |
| :--- | :--- |
| **Top-Down Exploration** | Bergerak bebas mengelilingi ruangan teknisi menggunakan Virtual D-Pad (layar sentuh) atau tombol `WASD` / `Arrow Keys` pada PC. |
| **Contextual Raycast Interaction** | Mendekati perangkat yang bermasalah (meja perakitan, rak kabel, server) akan memunculkan balon interaksi (*Action Bubble*) untuk membuka minigame kanvas 2D. |
| **Sistem 3 Nyawa (HP)** | 3 indikator nyawa berupa ikon hati/baterai tersenyum. Melakukan kesalahan fatal (misal salah urutan warna pin kabel atau salah klasifikasi IP) mengurangi 1 HP. |
| **Penalti Komikal (Anti-Frustrasi)** | Tidak ada efek tersetrum/mati menakutkan. Saat salah, layar bergoyang lembut (*screen bounce*), karakter mengeluarkan ekspresi pusing (mata spiral), dan perangkat cemberut lucu. |
| **Time-Attack & Star Rating** | Diberi batas waktu dinamis pada tiap level. Pemain mendapatkan evaluasi bintang 1 hingga 3 berdasarkan kecepatan penyelesaian dan sisa nyawa teknisi. |
| **Buku Panduan Interaktif (*In-Game Guidebook*)** | Panduan visual lengkap standar TIA/EIA 568A/B, kelas IP, dan diagram jaringan yang bisa dibuka kapan saja di tengah permainan dengan animasi *page flip*. |
| **Color Coding Ramah & Fungsional** | *Pastel Mint Green* (Status UP/Berhasil), *Baby Blue* (Standby/Normal), dan *Soft Coral Red* (Peringatan/Kerusakan). |

---

## 🗺️ 4. Struktur Kurikulum Permainan (5 Stages)

Permainan dirancang bertingkat selaras dengan modul pembelajaran resmi kurikulum Jaringan Komputer:

```
  ┌────────────────────────────────────────────────────────┐
  │                        STAGE 1                         │
  │     Physical & Data Link Layer (Gudang Hardware)       │
  │  1.1 Sortir Kabel Straight vs Cross                    │
  │  1.2 Perakitan Urutan Pin Kabel RJ45 (Standar T568A/B) │
  │  1.3 Unicast Switching vs Collision Domain             │
  └──────────────────────────┬─────────────────────────────┘
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                        STAGE 2                         │
  │      Network & Addressing (Koridor Server Utama)       │
  │  2.1 Klasifikasi Kelas IPv4 (Kelas A, B, dan C)        │
  │  2.2 Firewall Sederhana (IP Publik vs IP Privat)       │
  │  2.3 Protokol Resolusi Alamat (ARP-Request & Reply)    │
  └──────────────────────────┬─────────────────────────────┘
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                        STAGE 3                         │
  │        Subnetting & Routing (Ruang Kontrol)            │
  │  3.1 Pemisahan Net ID & Host ID                        │
  │  3.2 Kalkulator Nilai Prefiks CIDR vs Subnet Mask      │
  │  3.3 Validasi Usable Host (Tanpa Network/Broadcast)    │
  │  3.4 Merapikan Tabel Routing Dinamis                   │
  └──────────────────────────┬─────────────────────────────┘
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                        STAGE 4                         │
  │         Topologi & Infrastruktur (Area Luar)           │
  │  4.1 Jangkauan Jaringan (PAN, LAN, MAN, WAN)           │
  │  4.2 Pemulihan Topologi Star (Pusat Switch Rusak)      │
  │  4.3 Rekonstruksi Topologi Ring & Mesh                 │
  └──────────────────────────┬─────────────────────────────┘
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                        STAGE 5                         │
  │       OSI Layer & Protokol Transport (Mainframe)       │
  │  5.1 Menyusun 7 Lapisan OSI Layer                      │
  │  5.2 Alur Enkapsulasi PDU (Bits -> Frames -> Packets)  │
  │  5.3 Pemilahan Jalur TCP Aman vs UDP Real-Time         │
  │  5.4 Pemetaan Port Layanan (Port 80, 443, 22, dll)     │
  │  5.5 Rhythm Game: TCP Three-Way Handshake (SYN-ACK)    │
  └────────────────────────────────────────────────────────┘
```

---

## 🛠️ 5. Teknologi & Peralatan yang Digunakan

* **Game Engine:** [Godot Engine v4.x](https://godotengine.org/) (GDScript)
* **Target Platform:** Android (Smartphone & Tablet) & PC Windows
* **Build System:** Android SDK, JDK (Java 17 / Android Studio JBR), Gradle
* **Visual & Seni 2D:** Adobe Illustrator & Figma (Vektor 2D Flat Kawaii Doodle)
* **Audio Engineering:** Procedural Real-time Audio Synthesizer (Pure GDScript AudioStreamGenerator) & FL Studio / Audacity
* **Version Control:** Git & GitHub

---

## 📂 6. Struktur Direktori Repositori

```text
PING-/
├── build/                      # Hasil kompilasi paket Android
├── documentations/             # Proposal rancangan & modul referensi jaringan
│   └── PROPOSAL RANCANGAN GAME (4).pdf
├── ping-game/                  # Root project Godot Engine
│   ├── art/                    # Aset visual 2D (karakter, objek, UI, background)
│   ├── fonts/                  # Tipografi (Nunito, MADE Tommy Soft)
│   ├── scenes/                 # Scene Godot (.tscn & .gd)
│   │   ├── dashboard.tscn      # Menu utama & pemilihan stage
│   │   ├── level_path.tscn     # Peta jalur pemilihan level
│   │   ├── guidebook.tscn      # Buku panduan interaktif
│   │   ├── settings_modal.tscn # Modal pengaturan suara & haptic
│   │   └── gameplay/           # Scene gameplay interaktif
│   │       ├── level_1_1.gd    # Level 1.1: Pemilahan kabel
│   │       └── level_1_2.gd    # Level 1.2: Perakitan pin RJ45
│   ├── scripts/                # Singleton & Global Manager (PlayerData, SettingsManager)
│   ├── project.godot           # File konfigurasi utama Godot
│   └── export_presets.cfg      # Konfigurasi preset export Android
├── ping-game.apk               # File siap instal (Android Debug APK)
└── README.md                   # Dokumentasi game ini
```

---

## 🚀 7. Cara Menjalankan & Membangun Game

### Menjalankan di Godot Engine (PC Editor):
1. Unduh dan buka **Godot Engine v4.3+ / v4.7+ (Standard 64-bit)**.
2. Pilih **Import** lalu arahkan ke folder `PING-/ping-game/project.godot`.
3. Tekan **F5** atau klik tombol **Run Project** di pojok kanan atas editor.

### Membangun File Android APK:
Pastikan Android SDK dan JDK sudah terpasang di sistem, lalu jalankan:
```bat
export_android.bat
```
File APK hasil kompilasi akan otomatis diperbarui di direktori root: `ping-game.apk`.

---

## 👥 8. Tim Pengembang (Credits)

Game ini dikembangkan sebagai karya proyek mata kuliah **Pemrograman Game** oleh mahasiswa:
* **Abidah Azka Zaen Prasetyo** (25091397018) — *D4 Manajemen Informatika*
* **Lionel Jevon Chrismana Putra** (25091397019) — *D4 Manajemen Informatika*
* **Muhammad Ashim Dzulhilmi** (25091397027) — *D4 Manajemen Informatika*
* **Farradhisa Putri Listyaji** (25091367094) — *D4 Desain Grafis*

**Fakultas Vokasi — Universitas Negeri Surabaya (UNESA)**  
*Sumber Referensi: Modul Pembelajaran Jaringan Komputer D4 Manajemen Informatika.*
