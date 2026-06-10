# 📖 Dokumentasi Lengkap Aplikasi Teguk

Aplikasi **Teguk** adalah aplikasi pemantau hidrasi cerdas yang dibangun menggunakan Flutter. Aplikasi ini menggunakan pola arsitektur **MVVM (Model-View-ViewModel)** dengan bantuan *State Management* **Provider** untuk memisahkan antara antarmuka (UI), logika bisnis (State/Provider), dan komunikasi data (Repository/Service).

Berikut adalah bedah lengkap seluruh fitur aplikasi, alur logikanya, serta file-file yang berperan.

---

## 🏗️ 1. Arsitektur Inti (Pola Alur Data)

Setiap fitur dalam aplikasi Teguk selalu melewati 3 lapisan (layer) utama:

1. **Presentation Layer (UI/Screen)**: Semua file di dalam `lib/presentation/`. Ini adalah tampilan yang dilihat pengguna. Saat pengguna menekan tombol, file ini akan memanggil fungsi di *Provider*.
2. **Business Logic Layer (Provider)**: Semua file di dalam `lib/providers/`. Ini adalah "otak" aplikasi. Provider menyimpan status data (loading, success, dll) dan melakukan *request* ke lapisan Data.
3. **Data Layer (Repository/Service)**: 
   - `lib/data/repositories/`: Menghubungkan aplikasi dengan API backend eksternal (mengirim/menerima JSON via HTTP).
   - `lib/data/services/`: Mengakses fitur bawaan perangkat keras HP (GPS, Sensor, Kamera, Notifikasi).

---

## 🚀 2. Bedah Fitur & File yang Digunakan

### A. Autentikasi (Registrasi, Login, Splash Screen)
**Logika:** 
- Saat aplikasi dibuka, `SplashScreen` memanggil `AuthRepository.getToken()` untuk mengecek ketersediaan sesi (token JWT) di `SharedPreferences` lokal.
- Jika ada token, aplikasi mengecek _Role_ pengguna. Jika _User_ atau _HealthExpert_, diarahkan ke `DashboardScreen`. Jika _Admin_, diarahkan ke `AdminDashboardScreen`. Jika tidak ada token, masuk ke `LoginScreen`.
- Untuk mengatasi masalah nama kosong dari API, terdapat logika *fallback* menjadi "Pengguna" di `AuthRepository`.

**File yang Terlibat:**
- 🖼️ UI: `splash_screen.dart`, `auth/login_screen.dart`, `auth/register_screen.dart`
- 🧠 Logika: (Langsung memanggil Repository karena UI sederhana)
- 🔌 Data: `repositories/auth_repository.dart`, `repositories/user_repository.dart`

---

### B. Dasbor Utama & Pemantau Air (Dashboard)
**Logika:**
- Ini adalah layar beranda yang menggunakan sistem navigasi bawah (*BottomNavigationBar*) untuk berpindah ke tab lain (Riwayat, Aktivitas, Statistik, Konsultasi).
- Inti dari layar ini adalah `WaterProgressRing` yang menampilkan persentase cairan.
- Saat user memencet `QuickAddButton` (contoh: tambah 200ml), UI memanggil fungsi `addWater(200)` milik `WaterProvider`.
- `WaterProvider` pertama-tama akan mengupdate *state* UI agar berubah secara instan, menyimpannya di lokal (`SharedPreferences`), kemudian mencoba mengirim data tersebut ke Backend API melalui `WaterRepository`. Jika server gagal/timeout, data lokal tetap tersimpan.

**File yang Terlibat:**
- 🖼️ UI: `dashboard/dashboard_screen.dart`, `widgets/water_progress_ring.dart`, `widgets/quick_add_button.dart`
- 🧠 Provider: `providers/water_provider.dart`
- 🔌 Data: `repositories/water_repository.dart`

---

### C. Cuaca & Lokasi (Weather Banner)
**Logika:**
- Dasbor memiliki fitur deteksi ketinggian (Altitude) dan Cuaca.
- Saat aplikasi diinisialisasi, `WaterProvider` mulai mendengarkan stream GPS dari `LocationService`.
- Jika ketinggian pengguna terdeteksi > 1500 mdpl (pegunungan), `WaterProvider` akan memunculkan bendera peringatan ("Gunung terdeteksi, tambah target airmu?"). Jika pengguna setuju, target air ditambah 1000ml secara lokal.
- Secara paralel, `WeatherProvider` akan mengambil lokasi pengguna, lalu memanggil `WeatherService` untuk mengambil data cuaca dari API Cuaca publik (berdasarkan koordinat). Jika cuaca panas/terik, UI `WeatherBanner` akan menyesuaikan imbauannya.

**File yang Terlibat:**
- 🖼️ UI: `widgets/weather_banner.dart`
- 🧠 Provider: `providers/weather_provider.dart` (untuk cuaca), `providers/water_provider.dart` (untuk ketinggian)
- 🔌 Data: `services/location_service.dart`, `services/weather_service.dart`

---

### D. Sensor Langkah Kaki (Pedometer & Riwayat Aktivitas)
**Logika:**
- Layar ini tidak bergantung pada internet atau API Backend. Sepenuhnya menggunakan sensor perangkat.
- `ActivityProvider` akan mengaktifkan `PedometerService` yang meminta akses *Activity Recognition* ke Android.
- Pedometer membaca langkah. Karena sensor pedometer sifatnya menghitung terus sejak HP menyala (reboot), `PedometerService` membuat algoritma *baseline* (patokan harian). Langkah Hari Ini = (Langkah Total HP) - (Langkah Baseline saat pergantian hari).
- Setiap pukul 00:00 (pergantian hari), `PedometerService` akan menyimpan rekap langkah hari sebelumnya ke memori lokal HP (History) sebelum mereset jumlah langkah menjadi 0.

**File yang Terlibat:**
- 🖼️ UI: `activity/live_activity_screen.dart`
- 🧠 Provider: `providers/activity_provider.dart`
- 🔌 Data: `services/pedometer_service.dart`

---

### E. Pengingat Pintar (Smart Notifications)
**Logika:**
- Saat pengguna mengaktifkan "Pengingat Tiap Jam" di pengaturan profil, `NotificationService` dijalankan.
- Aplikasi menggunakan modul *timezone* (`tz`) dan `flutter_local_notifications`.
- Sistem tidak menggunakan alarm berulang biasa (karena sering dimatikan paksa oleh sistem penghemat baterai Android modern). Sebagai gantinya, aplikasi membuat **24 alarm tunggal unik** untuk 24 jam ke depan secara langsung ke kalender internal Android (`zonedSchedule`).
- Masing-masing alarm membawa *string/text* Tips Hidrasi yang dipilih secara acak (ala *Game Tips*).

**File yang Terlibat:**
- 🖼️ UI: `profile/profile_edit_screen.dart` (Hanya tombol *switch*)
- 🔌 Data: `services/notification_service.dart`

---

### F. Konsultasi Pakar & Chatting
**Logika:**
- Fitur ini memiliki dua layar utama: Daftar Pakar (`ConsultationScreen`) dan Layar Chat (`ChatScreen`).
- `ConsultationProvider` mengambil daftar *Health Expert* dari Backend API.
- Saat masuk ke layar Chat, aplikasi akan melakukan dua jenis pemanggilan API:
   1. HTTP GET via `ConsultationRepository` untuk menarik riwayat *chat* lama.
   2. HTTP POST untuk mengirim pesan baru ke Pakar.
- Fitur kamera juga dimanfaatkan di sini via `CameraService` jika pengguna ingin mengirim lampiran foto saat mendaftar menjadi pakar (`ExpertApplicationScreen`).

**File yang Terlibat:**
- 🖼️ UI: `consultation/consultation_screen.dart`, `consultation/chat_screen.dart`, `expert/expert_application_screen.dart`
- 🧠 Provider: `providers/consultation_provider.dart`
- 🔌 Data: `repositories/consultation_repository.dart`, `repositories/health_expert_repository.dart`, `services/camera_service.dart`

---

### G. Statistik & Riwayat
**Logika:**
- Fitur ini memanggil `StatisticRepository` dan `WaterRepository` untuk mengambil daftar JSON harian.
- `StatisticsProvider` mengolah data yang diterima menjadi grafik (jika menggunakan library chart) atau daftar visual di `StatisticsScreen`.
- `HistoryScreen` menampilkan riwayat harian langsung.

**File yang Terlibat:**
- 🖼️ UI: `history/history_screen.dart`, `statistics/statistics_screen.dart`
- 🧠 Provider: `providers/statistics_provider.dart`
- 🔌 Data: `repositories/statistic_repository.dart`, `repositories/water_repository.dart`

---

### H. Admin Dashboard
**Logika:**
- Hanya muncul jika akun login memiliki peran `Admin`.
- `AdminProvider` digunakan untuk mengambil daftar "Aplikasi Pakar" (pengguna yang mendaftar ingin menjadi *Health Expert*).
- Admin bisa melakukan Aksi (Terima/Tolak) yang akan memicu `AdminRepository.updateApplicationStatus()`.

**File yang Terlibat:**
- 🖼️ UI: `admin/admin_dashboard_screen.dart`
- 🧠 Provider: `providers/admin_provider.dart`
- 🔌 Data: `repositories/admin_repository.dart`

---

## 📂 3. Konfigurasi Dasar (`core/`)

Folder `core` menyimpan konfigurasi stabil yang dipakai di seluruh aplikasi, yaitu:
- `core/constants/api_constants.dart`: Menyimpan variabel URL Backend (contoh: `baseUrl = 'https://api.teguk.com'`).
- `core/theme/`: Pengaturan warna *default*, gaya tulisan, dll.
- `core/utils/`: Fungsi-fungsi bantuan (seperti format tanggal, konversi angka, dll).
- Konfigurasi sensitif (seperti IP lokal server/API Key cuaca) disimpan di dalam file `.env` di luar folder `lib`. File `main.dart` akan memuat file `.env` ini terlebih dahulu sebelum aplikasi *rendering*.

**Selesai!** Struktur teguk ini dirancang agar mudah dibaca dan diekspansi. Jika suatu saat Anda ingin mengganti backend ke layanan lain, Anda hanya perlu merombak folder `repositories/` tanpa menyentuh UI sama sekali.
