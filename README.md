# E-Kantin

Aplikasi pemesanan makanan dan minuman kantin kampus. Terdiri dari dua bagian:

- `backend/laravel_api` — REST API Laravel + PostgreSQL.
- `frontend/flutter_app` — aplikasi Flutter (mobile dan web) untuk Customer, Seller, dan Admin.

Dokumen kebutuhan dan desain lengkap ada di root proyek (`PRD.md`, `TECH_STACK.md`, `API_SPECIFICATION.md`, `ERD.md`, dan lainnya).

---

## 1. Fitur Utama

| Role | Fitur |
|---|---|
| Customer | Melihat daftar kantin, kategori, dan produk; mencari menu; melihat detail produk dan add-on; mengelola favorit; membuat pesanan; pembayaran simulasi QRIS; melihat riwayat dan status pesanan; mengubah profil. |
| Seller | Melihat dashboard; mengelola profil kantin (nama, deskripsi, jam buka, status buka/tutup); mengelola produk dan add-on; menerima, menolak, dan memproses pesanan sesuai status. |
| Admin | Melihat daftar Seller; membuat akun Seller; mengubah data Seller; mengaktifkan atau menonaktifkan akun Seller. |

---

## 2. Teknologi

| Lapisan | Teknologi |
|---|---|
| Frontend | Flutter 3.50 / Dart 3.14 |
| State management | Riverpod |
| Navigasi | GoRouter |
| HTTP client | Dio |
| Penyimpanan token | flutter_secure_storage |
| Backend | Laravel 13 / PHP 8.3 |
| Autentikasi API | Laravel Sanctum (Bearer token) |
| Database | PostgreSQL 17 |
| ORM | Eloquent |
| Testing backend | PHPUnit |
| Testing frontend | flutter_test |

---

## 3. Cara Kerja Aplikasi

### 3.1 Arsitektur

```text
Flutter (Customer / Seller / Admin)
        |
        | HTTP JSON + Bearer token
        v
Laravel REST API  /api/v1
        |
        | Eloquent
        v
PostgreSQL  (database: e_kantin)
```

Frontend hanya menampilkan data dan mengirim input. Harga, subtotal, total, status pesanan, dan hak akses dihitung dan divalidasi di backend.

### 3.2 Autentikasi dan otorisasi

1. User login lewat `POST /api/v1/auth/login` atau register lewat `POST /api/v1/auth/register`.
2. Backend mengembalikan token Sanctum.
3. Flutter menyimpan token di secure storage dan mengirim header `Authorization: Bearer <token>` pada setiap request.
4. Middleware `role:CUSTOMER`, `role:SELLER`, dan `role:ADMIN` membatasi endpoint sesuai role.
5. Router Flutter mengarahkan user ke halaman awal sesuai role:
   - Customer → `/customer/home`
   - Seller → `/seller`
   - Admin → `/admin/sellers`

### 3.3 Alur pesanan Customer

1. Customer memilih kantin, produk, jumlah, add-on, dan catatan.
2. Flutter memanggil `POST /api/v1/orders/preview` untuk menghitung harga di server.
3. Customer konfirmasi, lalu `POST /api/v1/orders` membuat order dengan status `WAITING_PAYMENT`.
4. Backend menyimpan snapshot nama dan harga produk/add-on agar riwayat tidak berubah saat katalog diedit.
5. Customer memulai pembayaran `POST /api/v1/orders/{order}/payments` (metode QRIS simulasi).
6. Hasil simulasi dikirim ke `POST /api/v1/payments/{payment}/simulate-result`:
   - `success` → pembayaran `SUCCESS`, order menjadi `PAID`.
   - `failed` → pembayaran `FAILED`, order tetap `WAITING_PAYMENT`.
7. Seller memproses order: terima (`CONFIRMED`), tolak (`REJECTED`), lalu `PREPARING` → `READY` → `COMPLETED`.
8. Customer memantau status lewat halaman riwayat dan detail pesanan.

### 3.4 Transisi status pesanan

```text
WAITING_PAYMENT ──> PAID ──> CONFIRMED ──> PREPARING ──> READY ──> COMPLETED
       │              │
       v              v
   CANCELLED      REJECTED
```

Aturan transisi ditegakkan di `app/Enums/OrderStatus.php` dan `app/Services/OrderService.php`. Perubahan status di luar aturan ditolak dengan error validasi.

### 3.5 Pembayaran

Pembayaran masih simulasi (mock), bukan payment gateway nyata. Endpoint simulasi otomatis ditolak saat `APP_ENV=production` (`app/Services/PaymentService.php`).

### 3.6 Pengelolaan katalog Seller

Seller hanya dapat mengelola kantin, produk, dan add-on miliknya. Setiap perubahan diverifikasi terhadap kepemilikan data. Admin hanya mengelola akun Seller, bukan katalog.

---

## 4. Struktur Proyek

```text
E-Kantin/
├── backend/
│   └── laravel_api/
│       ├── app/
│       │   ├── Enums/            # Role, OrderStatus, PaymentStatus, dll.
│       │   ├── Http/
│       │   │   ├── Controllers/Api/V1/
│       │   │   ├── Middleware/   # EnsureRole
│       │   │   ├── Requests/     # Validasi input
│       │   │   └── Resources/    # Format respons JSON
│       │   ├── Models/
│       │   ├── Policies/         # OrderPolicy
│       │   └── Services/         # OrderService, PaymentService
│       ├── database/
│       │   ├── migrations/
│       │   └── seeders/
│       ├── routes/api.php
│       └── .env.example
├── frontend/
│   └── flutter_app/
│       ├── lib/
│       │   ├── app/              # app.dart, router.dart, theme
│       │   ├── core/             # config, network, storage, errors, utils
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── customer/
│       │   │   ├── seller/
│       │   │   └── admin/
│       │   └── shared/           # model dan widget bersama
│       └── pubspec.yaml
└── *.md                          # dokumen kebutuhan dan desain
```

---

## 5. Prasyarat

Pastikan sudah terpasang:

- PHP 8.3 atau lebih baru, dengan ekstensi `pdo_pgsql` dan `pgsql`.
- Composer 2.x.
- PostgreSQL 14+ (proyek ini diuji dengan PostgreSQL 17).
- Flutter SDK 3.50+ (Dart 3.14+).
- Chrome (untuk menjalankan versi web) atau Android Studio/emulator.

Cek versi:

```powershell
php -v
composer -V
psql --version
flutter --version
```

---

## 6. Cara Menjalankan

### 6.1 Backend (Laravel)

Jalankan dari folder `backend/laravel_api`.

1. Install dependency:

```powershell
composer install
```

2. Siapkan file environment:

```powershell
Copy-Item .env.example .env
php artisan key:generate
```

3. Buat database PostgreSQL:

```powershell
$env:PGPASSWORD='postgres'
psql -U postgres -h 127.0.0.1 -c "CREATE DATABASE e_kantin"
```

4. Sesuaikan koneksi database di `.env`:

```dotenv
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=e_kantin
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

5. Jalankan migrasi dan seeder:

```powershell
php artisan migrate --seed
```

6. Buat symbolic link storage (untuk gambar produk):

```powershell
php artisan storage:link
```

7. Jalankan server:

```powershell
php artisan serve
```

API tersedia di `http://127.0.0.1:8000/api/v1`.

Catatan: jika database sudah pernah dimigrasi dan ingin mengulang dari awal:

```powershell
php artisan migrate:fresh --seed
```

Perintah ini menghapus seluruh data di database `e_kantin`.

### 6.2 Frontend (Flutter)

Jalankan dari folder `frontend/flutter_app`.

1. Install dependency:

```powershell
flutter pub get
```

2. Jalankan aplikasi:

```powershell
flutter run -d chrome
```

Atau untuk emulator/perangkat Android:

```powershell
flutter run
```

Alamat API otomatis menyesuaikan platform (`lib/core/config/app_config.dart`):

- Android emulator: `http://10.0.2.2:8000/api/v1`
- Web, desktop, iOS simulator: `http://127.0.0.1:8000/api/v1`

Untuk perangkat fisik atau alamat API lain, gunakan override:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Ganti `192.168.1.10` dengan IP komputer yang menjalankan backend, dan pastikan backend dijalankan dengan `php artisan serve --host=0.0.0.0`.

### 6.3 Urutan menjalankan

1. Terminal 1: `php artisan serve` di `backend/laravel_api`.
2. Terminal 2: `flutter run -d chrome` di `frontend/flutter_app`.
3. Login memakai akun seed di bawah.

---

## 7. Akun Seed

Semua password: `password`.

| Role | Email |
|---|---|
| Admin | `admin@ekantin.test` |
| Seller | `seller1@ekantin.test` |
| Seller | `seller2@ekantin.test` |
| Customer | `customer@ekantin.test` |

Seeder juga membuat dua kantin, kategori, produk, add-on, dan contoh pesanan dengan berbagai status.

---

## 8. Ringkasan Endpoint API

Semua endpoint memakai prefix `/api/v1`.

| Kelompok | Endpoint |
|---|---|
| Auth | `POST /auth/login`, `POST /auth/register`, `GET /auth/me`, `PATCH /auth/profile`, `POST /auth/logout` |
| Katalog publik | `GET /canteens`, `GET /canteens/{id}`, `GET /categories`, `GET /products`, `GET /products/{id}`, `GET /products/{id}/addons` |
| Media | `GET /media/{path}` |
| Customer | `GET/POST /favorites`, `DELETE /favorites/{product}`, `POST /orders/preview`, `POST /orders`, `GET /orders`, `GET /orders/{id}`, `GET /orders/{id}/status-history`, `POST /orders/{id}/payments`, `GET /payments/{id}`, `POST /payments/{id}/simulate-result` |
| Seller | `GET/PATCH /seller/canteen`, CRUD `/seller/products`, `POST /seller/products/{id}/addons`, `PATCH/DELETE /seller/addons/{id}`, `GET /seller/orders`, `GET /seller/order-history`, `POST /seller/orders/{id}/accept`, `POST /seller/orders/{id}/reject`, `PATCH /seller/orders/{id}/status` |
| Admin | `GET/POST /admin/sellers`, `GET/PATCH /admin/sellers/{id}`, `PATCH /admin/sellers/{id}/activation` |

Detail payload dan respons ada di `API_SPECIFICATION.md`.

---

## 9. Testing

Backend:

```powershell
cd backend\laravel_api
php artisan test
```

Frontend:

```powershell
cd frontend\flutter_app
flutter test
```

---

## 10. Troubleshooting

| Masalah | Solusi |
|---|---|
| `SQLSTATE[08006]` atau gagal koneksi database | Pastikan service PostgreSQL berjalan dan nilai `DB_*` di `.env` benar. |
| `could not find driver` | Aktifkan ekstensi `pdo_pgsql` dan `pgsql` di `php.ini`, lalu restart terminal. |
| `Unable to locate file in Vite manifest` | Tidak dipakai pada proyek ini; backend hanya REST API. Jika muncul, jalankan `npm install` lalu `npm run build`. |
| Flutter tidak bisa terhubung ke API di emulator | Gunakan `10.0.2.2`, bukan `127.0.0.1`. |
| Flutter di perangkat fisik tidak terhubung | Jalankan backend dengan `php artisan serve --host=0.0.0.0` dan pakai `--dart-define=API_BASE_URL=http://IP-LAN:8000/api/v1`. |
| Gambar produk tidak tampil | Jalankan `php artisan storage:link`. |
| Perubahan kode backend tidak muncul | Hentikan dan jalankan ulang `php artisan serve`, atau bersihkan cache dengan `php artisan optimize:clear`. |
| Login gagal setelah `migrate:fresh` | Pastikan memakai `--seed` agar akun contoh dibuat. |

---

## 11. Dokumentasi Terkait

- `PRD.md` — kebutuhan produk.
- `TECH_STACK.md` — teknologi dan batasan implementasi.
- `SYSTEM_ARCHITECTURE.md` — arsitektur sistem.
- `API_SPECIFICATION.md` — spesifikasi endpoint.
- `ERD.md` dan `database.md` — struktur database.
- `BUSINESS_RULES.md` — aturan bisnis.
- `TESTING_STRATEGY.md` dan `TEST_CASES.md` — strategi dan kasus pengujian.
- `DEPLOYMENT.md` — panduan deployment.
