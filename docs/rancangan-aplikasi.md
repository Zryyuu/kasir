# Rancangan Final Aplikasi Kasir — Pisang Keju Sinar

Dokumen ini adalah versi final rancangan **Sinar Kasir** setelah revisi.
Dipakai sebagai acuan konsultasi dan implementasi.

---

## 1. Ringkasan

| Item | Keterangan |
| --- | --- |
| Nama aplikasi | **Sinar Kasir** |
| Nama usaha | Pisang Keju Sinar |
| Jenis | Aplikasi kasir sederhana untuk satu UMKM |
| Platform utama | Android (Flutter), offline |
| Pengguna | Pemilik / kasir |
| Tujuan | Mencatat penjualan, stok porsi, pemasukan manual, pengeluaran manual, dan saldo |
| Mata uang | Rupiah, format wajib bertitik: `Rp20.000` |
| Tema warna | Biru |

### Batasan MVP

- Satu perangkat, tanpa login, tanpa cloud.
- Tidak ada kasbon/utang pelanggan.
- Tidak ada kategori makanan/minuman. **Produk langsung menjadi varian** dan masing-masing punya stok porsi.
- Tidak ada pajak, diskon, atau promo otomatis.
- Cetak struk memakai **dialog print sistem / PDF**. Printer thermal Bluetooth bisa ditambahkan nanti.

---

## 2. Konsep Produk dan Stok

Karena yang dijual adalah produk matang, tidak perlu kategori makanan/minuman.

**Produk = varian menu.** Contoh:

| Produk / Varian | Harga | Stok |
| --- | --- | --- |
| Pisang Goreng Original | Rp6.000 | 30 porsi |
| Pisang Coklat | Rp7.000 | 30 porsi |
| Pisang Keju | Rp8.000 | 30 porsi |
| Pisang Keju Coklat | Rp9.000 | 25 porsi |
| Pisang Keju Susu | Rp10.000 | 20 porsi |
| Pisang Keju Crispy | Rp10.000 | 20 porsi |

Aturan:

1. Stok dihitung dalam **porsi**.
2. Satu porsi terjual = stok berkurang satu.
3. Produk dengan stok `0` tidak bisa dipilih dan diberi label **HABIS**.
4. Stok menipis (`<= 5`) diberi penanda khusus.
5. Stok bisa ditambah lewat halaman Produk.
6. Produk tidak dihapus permanen, cukup dinonaktifkan agar riwayat lama tetap valid.
7. Setiap perubahan stok manual wajib punya alasan: **Restock**, **Koreksi stok**,
   **Rusak**, **Terbuang**, **Hilang**, atau **Lainnya**.
8. Stok **Rusak**, **Terbuang**, dan **Hilang** otomatis dicatat sebagai
   pengeluaran **Kerugian Stok** sebesar `qty x harga jual`, sehingga
   mengurangi saldo.
9. Stok awal saat produk dibuat dicatat dengan alasan **Stok awal**.

---

## 3. Navigasi

### Bottom Navigation (5 menu)

1. **Beranda**
2. **Kasir**
3. **Riwayat**
4. **Laporan**
5. **Keuangan** — berisi tab Pengeluaran dan Pemasukan

### Aksi Cepat di Beranda (6 tombol)

1. Kasir
2. Produk
3. Riwayat
4. Pengeluaran
5. Pemasukan
6. Laporan

Produk tetap lewat aksi cepat. **Pengeluaran** dan **Pemasukan** langsung
membuka form catat dari Beranda tanpa harus pindah ke tab Keuangan.
Pengaturan toko lewat ikon ⚙️ di pojok kanan atas.

```text
Mulai
  -> Buka Aplikasi
  -> Inisialisasi database & pengaturan
  -> Halaman Dashboard (Beranda)

DARI DASHBOARD
  -> Bottom Navigation:
     -> Beranda
     -> Kasir
     -> Riwayat
     -> Laporan
     -> Keuangan (tab Pengeluaran / Pemasukan)
  -> Aksi Cepat:
     -> Kasir
     -> Produk
     -> Riwayat
     -> Pengeluaran
     -> Pemasukan
     -> Laporan
  -> Ikon Pengaturan
     -> Pengaturan Toko
     -> Kembali ke Dashboard

ALUR KASIR
  -> Halaman Kasir
  -> Keranjang & Checkout
  -> Struk Digital
     -> Cetak -> Dialog Print Sistem / PDF
     -> Bagikan -> PDF
     -> Tutup -> Kembali ke Kasir

ALUR RIWAYAT
  -> Daftar Riwayat
  -> Detail Transaksi
  -> Struk Digital

ALUR KELOLA PRODUK
  Mulai (oval)
  -> Halaman Produk (persegi panjang)
  -> Tampilkan daftar produk (jajar genjang)
  -> Pilih aksi (belah ketupat)
     -> Tambah Produk (persegi panjang)
        -> Isi nama, harga, stok (jajar genjang)
        -> Simpan (persegi panjang)
     -> Edit Produk (persegi panjang)
        -> Ubah nama / harga (jajar genjang)
        -> Simpan (persegi panjang)
     -> Atur Stok (persegi panjang)
        -> Pilih alasan perubahan (belah ketupat)
        -> Input jumlah & catatan (jajar genjang)
        -> Simpan (persegi panjang)
        -> Rusak / Terbuang / Hilang -> catat Kerugian Stok (persegi panjang)
     -> Nonaktifkan / Aktifkan (persegi panjang)
  -> Daftar produk diperbarui (persegi panjang)
  -> Produk tampil di Kasir (persegi panjang)
  -> Selesai (oval)

ALUR KEUANGAN
  -> Dari Beranda: Aksi Cepat Pengeluaran / Pemasukan
     -> Form catat keuangan
     -> Simpan
     -> Ringkasan Beranda diperbarui
  -> Dari halaman Keuangan
     -> Tab Pengeluaran / Pemasukan
     -> Form catat keuangan
     -> Simpan
     -> Daftar & total bulan diperbarui
  -> Edit / hapus catatan lewat daftar Keuangan

ALUR LAPORAN
  -> Halaman Laporan
  -> Pilih transaksi
  -> Detail Transaksi / Struk
```

---

## 4. Alur Kasir dan Penjualan

```text
Mulai
  -> Halaman Kasir
  -> Tampilkan daftar varian dan stok
  -> Pilih atau cari produk
  -> Cek stok
     -> Stok habis -> tampilkan label HABIS -> kembali pilih produk
     -> Stok ada -> tambahkan ke keranjang
  -> Ubah jumlah / hapus item (opsional)
  -> Tekan Bayar
  -> Keranjang kosong?
     -> Ya -> tampilkan pesan keranjang kosong -> kembali ke Kasir
     -> Tidak -> pilih metode pembayaran
  -> Metode pembayaran:
     -> QRIS -> uang pas = total, tanpa input
     -> Tunai -> uang pas = total, tanpa input
  -> Simpan transaksi + item + kurangi stok (satu transaksi database)
  -> Tampilkan struk digital
  -> Aksi struk:
     -> Cetak -> dialog print / simpan PDF
     -> Bagikan -> PDF
     -> Tutup -> kosongkan keranjang -> kembali ke Kasir
  -> Selesai
```

Catatan teknis:

- Simpan transaksi, simpan item, dan kurangi stok dilakukan dalam **satu database transaction**.
- Jika stok tidak cukup, seluruh transaksi dibatalkan.
- Nama dan harga produk disalin ke detail transaksi agar struk lama tidak berubah saat harga diedit.

---

## 5. Alur Riwayat Transaksi dan Cetak Struk

### 5.1 Riwayat Transaksi

Fitur:

- Daftar seluruh transaksi, terbaru di atas.
- Filter: Hari Ini, 7 Hari, Bulan Ini, Pilih Tanggal.
- Pencarian berdasarkan nomor nota.
- Filter metode: Semua, Tunai, QRIS.
- Setiap kartu menampilkan: nomor nota, jam, metode, jumlah item, dan total.
- Ketuk kartu untuk membuka detail transaksi.

### 5.2 Detail Transaksi

Menampilkan:

- Nomor nota
- Tanggal dan jam
- Nama kasir
- Metode pembayaran
- Daftar item: nama, qty, harga, subtotal
- Total belanja
- Tombol: **Cetak**, **Bagikan**, **Tutup**

### 5.3 Cetak Struk (Standar)

Fitur disediakan, tetapi pemakaiannya opsional.

- **Cetak** membuka dialog print bawaan perangkat.
- Struk dibuat sebagai PDF ukuran kertas thermal 58 mm.
- Bisa juga disimpan sebagai PDF lewat dialog tersebut.
- **Bagikan** membagikan PDF struk.
- **Tutup** menutup detail struk dan kembali ke halaman sebelumnya.
- Untuk printer thermal Bluetooth, bisa ditambahkan sebagai pengembangan berikutnya.

```text
Mulai
  -> Halaman Riwayat
  -> Pilih filter periode / metode
  -> Ambil daftar transaksi
  -> Tampilkan kartu transaksi
  -> Pilih transaksi?
     -> Tidak -> tetap di Riwayat
     -> Ya -> tampilkan detail transaksi & item
  -> Aksi struk:
     -> Cetak -> buat PDF 58 mm -> dialog print sistem -> kembali ke detail
     -> Bagikan -> bagikan PDF -> kembali ke detail
     -> Tutup -> daftar riwayat
  -> Selesai
```

---

## 6. Alur Keuangan Manual

Pengeluaran dan pemasukan sama-sama dicatat manual.
Di aplikasi dibuat satu halaman **Keuangan** dengan dua tab.

### 6.1 Pengeluaran

Kategori awal:

- Beli Bahan
- Gas & Listrik
- Transportasi
- Gaji
- Sewa
- Peralatan
- Kerugian Stok
- Lainnya

Field: kategori, nominal, keterangan, tanggal.

Catatan: stok **Rusak**, **Terbuang**, dan **Hilang** otomatis membuat
pengeluaran kategori **Kerugian Stok** dari halaman Atur Stok.

### 6.2 Pemasukan

Sumber awal:

- Modal
- Penjualan Lain
- Jual Sisa
- Titipan
- Lainnya

Field: kategori, nominal, keterangan, tanggal.

Modal dicatat sebagai pemasukan agar uang masuk terlihat, lalu dipakai untuk
membayar pengeluaran. Saldo bulan berjalan dihitung dari seluruh pemasukan
dikurangi pengeluaran.

### 6.3 Alur Simpel

Dari Beranda, pengguna bisa mencatat tanpa membuka halaman Keuangan:

```text
Mulai
  -> Beranda
  -> Aksi Cepat: Pengeluaran / Pemasukan
  -> Form catat keuangan
  -> Isi nominal
  -> Pilih kategori
  -> Catatan & tanggal (opsional)
  -> Simpan
  -> Ringkasan Beranda dan halaman Keuangan diperbarui
  -> Selesai
```

Dari halaman Keuangan, alurnya sama:

```text
Mulai
  -> Keuangan
  -> Pilih tab Pengeluaran / Pemasukan
  -> Tekan tombol tambah
  -> Form catat keuangan
  -> Simpan
  -> Daftar & total bulan diperbarui
  -> Selesai
```

Form yang sama dipakai untuk tambah, edit, dan hapus. Nominal wajib lebih dari 0,
kategori sudah terpilih otomatis, sedangkan catatan dan tanggal memakai default
yang bisa diubah.

### 6.4 Rumus Saldo

```
Saldo = Penjualan + Pemasukan - Pengeluaran
```

---

## 7. Alur Laporan

Filter periode:

- Hari Ini
- 7 Hari Terakhir
- Bulan Ini
- Pilih Tanggal

Isi laporan:

- Kartu **Penjualan**
- Kartu **Pemasukan**
- Kartu **Pengeluaran**
- Kartu **Saldo**
- Jumlah transaksi dan total porsi terjual
- Rata-rata nilai per transaksi
- Grafik harian pemasukan vs pengeluaran
- Produk terlaris
- Rincian pengeluaran per kategori
- Daftar transaksi pada periode, bisa menuju detail/riwayat

```text
Mulai
  -> Halaman Laporan
  -> Pilih periode
  -> Ambil transaksi
  -> Ambil pemasukan manual
  -> Ambil pengeluaran
  -> Hitung penjualan & porsi terjual
  -> Hitung saldo
  -> Hitung produk terlaris & rata-rata transaksi
  -> Tampilkan ringkasan, grafik harian, rincian, dan daftar transaksi
  -> Pilih transaksi?
     -> Ya -> Detail Transaksi / Struk
     -> Tidak -> Selesai
```

---

## 8. Rancangan Data

```text
TABEL products
  id            PK
  name          nama varian
  price         harga per porsi
  stock         stok porsi
  emoji         ikon tampilan
  active        tampil di kasir
  created_at    waktu dibuat

TABEL transactions
  id              PK
  number          PJS-YYYYMMDD-XXX
  payment_method  Tunai / QRIS
  subtotal
  total
  payed
  change
  created_at

TABEL sale_items
  id              PK
  transaction_id  FK -> transactions.id
  product_id      FK -> products.id
  name            nama produk saat transaksi
  price           harga saat transaksi
  qty             jumlah porsi
  subtotal

TABEL cash_entries
  id          PK
  kind        pemasukan / pengeluaran
  category    kategori atau sumber
  amount
  note
  created_at

TABEL stock_adjustments
  id            PK
  product_id    ID produk
  product_name  nama produk saat penyesuaian
  qty_change    positif tambah, negatif kurangi
  reason        Restock / Koreksi stok / Rusak / Terbuang / Hilang / Lainnya
  note          catatan opsional
  loss_amount   nilai kerugian (qty x harga jual)
  created_at

RELASI
  products (1) -> (banyak) sale_items
  products (1) -> (banyak) stock_adjustments
  transactions (1) -> (banyak) sale_items
```

Keterangan:

- Tidak ada tabel kategori produk. Varian langsung disimpan di `products`.
- Pemasukan dan pengeluaran manual memakai satu tabel `cash_entries` dengan pembeda `kind`.
- Stok rusak/terbuang/hilang menulis ke `stock_adjustments` sekaligus membuat
  pengeluaran **Kerugian Stok** di `cash_entries`.
- Pengaturan toko (nama usaha, nama kasir) disimpan di `SharedPreferences`.

---

## 9. Rancangan Layar

### 9.1 Beranda

```
┌─────────────────────────────────────────┐
│  🍌 Pisang Keju Sinar              ⚙️  │
│  Kelola penjualan & keuangan            │
├─────────────────────────────────────────┤
│  RINGKASAN HARI INI                     │
│  ┌───────────────────────────────────┐ │
│  │ Saldo             Rp165.000      │ │
│  │ Penjualan         Rp200.000      │ │
│  │ Pemasukan         Rp0            │ │
│  │ Pengeluaran       Rp35.000       │ │
│  │ 12 transaksi · 34 porsi          │ │
│  └───────────────────────────────────┘ │
│                                         │
│  AKSI CEPAT                             │
│  [ Kasir ]       [ Produk ]             │
│  [ Riwayat ]     [ Pengeluaran ]        │
│  [ Pemasukan ]   [ Laporan ]            │
│                                         │
│  TRANSAKSI TERAKHIR                     │
│  PJS-02112026-001 · Tunai · Rp25.000   │
│  PJS-02112026-002 · QRIS  · Rp18.000   │
├─────────────────────────────────────────┤
│  🏠      🛒      🧾      📊      💰    │
│ Beranda Kasir Riwayat Laporan Keuangan │
└─────────────────────────────────────────┘
```

### 9.2 Kasir

```
┌─────────────────────────────────────────┐
│  ← Kasir                    [Kosongkan] │
│  [ 🔍 Cari produk...                  ] │
│  Semua varian · stok porsi              │
│                                         │
│  ┌─────────────┐  ┌─────────────┐       │
│  │ Pisang      │  │ Pisang      │       │
│  │ Goreng Orig │  │ Keju        │       │
│  │ Rp6.000     │  │ Rp8.000     │       │
│  │ Sisa 24     │  │ Sisa 15     │       │
│  └─────────────┘  └─────────────┘       │
│  ┌─────────────┐  ┌─────────────┐       │
│  │ Pisang      │  │ Pisang      │       │
│  │ Coklat      │  │ Keju Susu   │       │
│  │ Rp7.000     │  │ Rp10.000    │       │
│  │ Sisa 30     │  │ Sisa 5      │       │
│  └─────────────┘  └─────────────┘       │
├─────────────────────────────────────────┤
│  3 item · Rp23.000          [ BAYAR ]  │
└─────────────────────────────────────────┘
```

### 9.3 Checkout

```
┌─────────────────────────────────────────┐
│  Pembayaran                          ✕ │
├─────────────────────────────────────────┤
│  Total Belanja       Rp23.000           │
│  Metode       [ TUNAI ] [ QRIS ]        │
│                                         │
│  Uang pas otomatis, tanpa input         │
│  nominal dan tanpa kembalian.           │
│                                         │
│          [ SIMPAN TRANSAKSI ]           │
└─────────────────────────────────────────┘
```

### 9.4 Riwayat Transaksi

```
┌─────────────────────────────────────────┐
│  Riwayat Transaksi                      │
│  [🔍 Cari nomor nota...              ]  │
│  [Hari Ini] [7 Hari] [Bulan Ini]        │
│  [Semua] [Tunai] [QRIS]                 │
├─────────────────────────────────────────┤
│  PJS-02112026-002        Rp18.000       │
│  14:32 · QRIS · 2 item · 3 porsi        │
│  ─────────────────────────────────────  │
│  PJS-02112026-001        Rp25.000       │
│  14:10 · Tunai · 3 item · 4 porsi       │
├─────────────────────────────────────────┤
│  Ketuk transaksi → detail & cetak struk │
└─────────────────────────────────────────┘
```

### 9.5 Detail Struk

```
┌─────────────────────────────────────────┐
│  Detail Transaksi                    ✕ │
├─────────────────────────────────────────┤
│  PISANG KEJU SINAR                      │
│  PJS-02112026-001                       │
│  02/11/2026 14:10 · Kasir: Sinar        │
│  Metode: Tunai                          │
│  ─────────────────────────────────────  │
│  Pisang Keju        2 x Rp8.000 16.000  │
│  Pisang Coklat      1 x Rp7.000  7.000  │
│  ─────────────────────────────────────  │
│  Total                    Rp23.000      │
│  Bayar                    Rp23.000      │
│  ─────────────────────────────────────  │
│  [ Cetak ]  [ Bagikan ]                 │
│  [ Tutup ]                              │
└─────────────────────────────────────────┘
```

### 9.6 Keuangan

```
┌─────────────────────────────────────────┐
│  Keuangan                               │
│  [ Pengeluaran ] [ Pemasukan ]           │
│                                         │
│  November 2026                          │
│  Total Pengeluaran      Rp350.000       │
│  2 catatan · Saldo      Rp1.150.000     │
│                                         │
│  Beli Minyak            Rp35.000        │
│  02/11/2026 · 14:10                     │
│  Gas & Listrik          Rp20.000        │
│  02/11/2026 · 09:00                     │
│                                         │
│                        [ + Tambah ]     │
└─────────────────────────────────────────┘
```

### 9.6.1 Form Catat Keuangan

```
┌─────────────────────────────────────────┐
│  Tambah Pengeluaran              [×]    │
│  Nominal [ Rp20.000 ]                   │
│  Kategori                               │
│  [Beli Bahan] [Gas & Listrik] [Gaji]    │
│  Catatan [ beli minyak goreng ]         │
│  Tanggal [ 03/11/2026 ]                 │
│  [ Simpan ]                             │
└─────────────────────────────────────────┘
```

Form yang sama dipakai untuk **Pengeluaran**, **Pemasukan**, dan edit catatan.
Untuk pemasukan, pilihan kategori diawali **Modal**.

### 9.7 Produk

```
┌─────────────────────────────────────────┐
│  Produk / Varian               [+ Tambah]│
│  [🔍 Cari produk...                  ]  │
├─────────────────────────────────────────┤
│  Pisang Keju                            │
│  Rp8.000 · Stok 15 porsi                │
│              [Edit] [Atur Stok & Alasan]│
│  ─────────────────────────────────────  │
│  Pisang Coklat                          │
│  Rp7.000 · Stok 30 porsi                │
│              [Edit] [Atur Stok & Alasan]│
└─────────────────────────────────────────┘
```

### 9.7.1 Atur Stok & Alasan

```
┌─────────────────────────────────────────┐
│  Pisang Keju                            │
│  Stok saat ini: 15 porsi                │
│  [ Tambah ]  [ Kurangi ]                │
│  Jumlah [ 5 ] porsi                     │
│  Alasan [ Rusak ▼ ]                     │
│  Catatan [ jatuh saat pengiriman ]      │
│  ⚠ Kerugian Rp40.000 akan dicatat       │
│    sebagai pengeluaran.                 │
│  [ Simpan Perubahan Stok ]              │
└─────────────────────────────────────────┘
```

### 9.8 Laporan

```
┌─────────────────────────────────────────┐
│  Laporan                                │
│  [Hari Ini] [7 Hari] [Bulan Ini] [Pilih]│
├─────────────────────────────────────────┤
│  Saldo                 Rp165.000         │
│  Penjualan            Rp200.000         │
│  Pemasukan            Rp0               │
│  Pengeluaran          Rp35.000          │
│  12 transaksi · 34 porsi                │
├─────────────────────────────────────────┤
│  Grafik pemasukan vs pengeluaran        │
│  ▁ ▃ ▅ █ ▆ ▄ ▂                          │
├─────────────────────────────────────────┤
│  Produk Terlaris                        │
│  1. Pisang Keju         9 porsi         │
│  2. Pisang Goreng Orig  7 porsi         │
├─────────────────────────────────────────┤
│  Rincian Pengeluaran                    │
│  Beli Minyak           Rp35.000         │
└─────────────────────────────────────────┘
```

### 9.9 Pengaturan

- Nama usaha
- Nama kasir
- Reset data dengan konfirmasi
- Versi aplikasi

---

## 10. Arsitektur Teknis

```text
Mulai
  -> Flutter UI
  -> Provider (state aplikasi)
     -> SQLite (sqflite) untuk produk, transaksi, item, keuangan
     -> SharedPreferences untuk pengaturan toko
     -> SaleService untuk simpan transaksi + kurangi stok
     -> ReceiptService untuk struk
  -> SaleService -> SQLite
  -> ReceiptService -> PDF / Dialog Print Sistem
  -> Selesai
```

| Lapisan | Teknologi |
| --- | --- |
| Framework | Flutter |
| State | Provider (`ChangeNotifier`) |
| Database | SQLite (`sqflite`) |
| Pengaturan | `shared_preferences` |
| Format uang/tanggal | `intl`, locale `id_ID` |
| Cetak struk | `pdf` + `printing` |
| Bagikan | `pdf` + `printing` (`Printing.sharePdf`) |

### Struktur folder

```
lib/
├── main.dart
├── core/
│   ├── app_theme.dart
│   └── formatters.dart
├── data/
│   └── app_database.dart
├── models/
│   ├── product.dart
│   ├── cart_item.dart
│   ├── sale_transaction.dart
│   ├── sale_item.dart
│   └── cash_entry.dart
├── providers/
│   ├── settings_provider.dart
│   ├── catalog_provider.dart
│   ├── cart_provider.dart
│   ├── transaction_provider.dart
│   ├── cash_entry_provider.dart
│   └── shell_controller.dart
├── services/
│   ├── sale_service.dart
│   └── receipt_service.dart
├── screens/
│   ├── root_shell.dart
│   ├── home_screen.dart
│   ├── pos_screen.dart
│   ├── history_screen.dart
│   ├── reports_screen.dart
│   ├── finance_screen.dart
│   └── products_screen.dart
└── widgets/
    ├── empty_state.dart
    ├── quick_action_tile.dart
    ├── section_header.dart
    ├── product_card.dart
    ├── stat_card.dart
    ├── cart_sheet.dart
    ├── receipt_sheet.dart
    └── settings_sheet.dart
```

---

## 11. Format Tampilan

- Uang: `Rp20.000`, `Rp6.000`, `Rp165.000` — selalu pakai titik ribuan.
- Tanggal: `02/11/2026`.
- Jam: `14:10`.
- Nomor nota: `PJS-20261102-001`.
- Stok: `15 porsi`.
- Metode: badge **Tunai** atau **QRIS**.

---

## 12. Rencana Pengerjaan

| Tahap | Pekerjaan |
| --- | --- |
| 1 | Setup proyek, tema, database, seed produk, format Rupiah |
| 2 | Halaman Produk/Varian: tambah, edit, stok + alasan, nonaktifkan |
| 3 | Kasir: keranjang, checkout tunai/QRIS uang pas, simpan transaksi |
| 4 | Riwayat transaksi + detail + cetak/bagikan/tutup struk |
| 5 | Keuangan: pengeluaran dan pemasukan manual |
| 6 | Beranda + laporan + grafik |
| 7 | Pengaturan, empty state, validasi, pengujian |

---

## 13. Skenario Pengujian

1. Aplikasi pertama kali dibuka menampilkan varian produk contoh.
2. Tambah produk ke keranjang, ubah qty, hapus item.
3. Checkout tunai dengan uang pas.
4. Checkout QRIS otomatis uang pas.
5. Stok berkurang setelah transaksi dan tidak bisa minus.
6. Produk stok 0 berlabel HABIS dan tidak bisa dipilih.
7. Transaksi muncul di Beranda dan Riwayat.
8. Detail riwayat menampilkan item, total, dan bayar.
9. Cetak struk membuka dialog print dan menghasilkan PDF.
10. Bagikan struk mengirim PDF.
11. Pengeluaran manual mengurangi saldo.
12. Pemasukan manual menambah saldo.
13. Atur stok **Rusak** / **Terbuang** / **Hilang** menambah pengeluaran
    **Kerugian Stok** dan mengurangi saldo.
14. Atur stok **Restock** menambah stok tanpa mengurangi saldo.
15. Laporan hari ini, 7 hari, bulan ini, dan rentang tanggal sesuai.
16. Format uang selalu bertitik ribuan.
17. Reset data mengosongkan transaksi dan keuangan, lalu seed produk kembali.

---

## 14. Cetak Struk: Catatan Keputusan

Yang dipakai di MVP:

- **Cetak** → PDF 58 mm → dialog print sistem Android/iOS.
- **Bagikan** → PDF struk.
- **Tutup** → kembali ke halaman sebelumnya.

Alasannya:

- Tidak perlu pairing printer tertentu.
- Bisa dipakai untuk printer apa pun yang didukung sistem.
- Tetap sederhana dan tidak menambah kompleksitas Bluetooth.
- Kalau nanti pemilik punya printer thermal Bluetooth, tinggal tambah layar pengaturan printer.

---

## 15. Pertanyaan Terakhir Sebelum Implementasi

1. Daftar varian final: apakah 6 varian contoh di atas sudah cukup?
2. Harga dan stok awal tiap varian.
3. Nama kasir default.
4. Apakah perlu logo/foto toko, atau cukup emoji 🍌?
5. Apakah cetak via dialog print sistem sudah cukup, atau langsung ingin printer thermal Bluetooth?
