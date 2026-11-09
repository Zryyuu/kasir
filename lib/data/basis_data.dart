import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../inti/keamanan.dart';

/// Lapisan basis data lokal (SQLite).
///
/// Semua data disimpan di perangkat. Penjualan, detail item, dan pengurangan
/// stok ditulis dalam satu transaksi basis data agar tidak ada data setengah jadi.
class BasisData {
  BasisData._();

  static final BasisData instance = BasisData._();

  static bool _ffiSiap = false;

  static void _pastikanFfi() {
    if (_ffiSiap) return;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiSiap = true;
  }

  static const int _versi = 8;
  static const String _namaBerkas = 'sinar_kasir.db';

  // Nama tabel (Indonesia)
  static const tProduk = 'produk';
  static const tTransaksi = 'transaksi';
  static const tItemPenjualan = 'item_penjualan';
  static const tCatatanKas = 'catatan_kas';
  static const tPengguna = 'pengguna';
  static const tPenyesuaianStok = 'penyesuaian_stok';
  static const tTambahan = 'tambahan';
  static const tTambahanItemPenjualan = 'tambahan_item_penjualan';

  Database? _basisData;
  Future<Database>? _membuka;

  Future<Database> get database async {
    final cached = _basisData;
    if (cached != null) return cached;
    final opening = _membuka ??= _buka();
    try {
      final db = await opening;
      _basisData = db;
      return db;
    } finally {
      if (identical(_membuka, opening)) _membuka = null;
    }
  }

  Future<Database> _buka() async {
    _pastikanFfi();
    final dir = await getDatabasesPath();
    final path = p.join(dir, _namaBerkas);
    return openDatabase(
      path,
      version: _versi,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.rawQuery('PRAGMA synchronous = FULL');
      },
      onCreate: (db, version) async {
        await _buatSkema(db);
        await _isiProdukAwal(db);
        await _isiPenggunaAwal(db);
      },
      onUpgrade: (db, versiLama, versiBaru) async {
        if (versiLama < 8) {
          await _migrasiKeIndonesia(db);
        } else {
          await _migrasiPin(db);
        }
      },
    );
  }

  Future<void> _buatSkema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tProduk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga REAL NOT NULL DEFAULT 0,
        stok INTEGER NOT NULL DEFAULT 0,
        aktif INTEGER NOT NULL DEFAULT 1,
        dibuat_pada INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tTransaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor TEXT NOT NULL UNIQUE,
        metode_pembayaran TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        dibayar REAL NOT NULL DEFAULT 0,
        kembalian REAL NOT NULL DEFAULT 0,
        id_pengguna INTEGER,
        dibuat_pada INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_transaksi_dibuat_pada ON $tTransaksi(dibuat_pada)',
    );

    await db.execute('''
      CREATE TABLE $tItemPenjualan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_transaksi INTEGER NOT NULL,
        id_produk INTEGER NOT NULL,
        nama TEXT NOT NULL,
        harga REAL NOT NULL DEFAULT 0,
        jumlah INTEGER NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (id_transaksi) REFERENCES $tTransaksi(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_item_penjualan_transaksi ON $tItemPenjualan(id_transaksi)',
    );

    await db.execute('''
      CREATE TABLE $tCatatanKas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jenis TEXT NOT NULL,
        kategori TEXT NOT NULL,
        jumlah REAL NOT NULL DEFAULT 0,
        keterangan TEXT,
        dibuat_pada INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_catatan_kas_dibuat_pada ON $tCatatanKas(dibuat_pada)',
    );

    await db.execute('''
      CREATE TABLE $tPengguna (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pengguna TEXT NOT NULL UNIQUE,
        pin TEXT NOT NULL,
        nama_lengkap TEXT NOT NULL,
        peran TEXT NOT NULL,
        aktif INTEGER NOT NULL DEFAULT 1,
        dibuat_pada INTEGER NOT NULL,
        terakhir_masuk_pada INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tPenyesuaianStok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_produk INTEGER NOT NULL,
        nama_produk TEXT NOT NULL,
        perubahan_jumlah INTEGER NOT NULL,
        alasan TEXT NOT NULL,
        catatan TEXT,
        nilai_kerugian REAL NOT NULL DEFAULT 0,
        dibuat_pada INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_penyesuaian_stok_produk ON $tPenyesuaianStok(id_produk, dibuat_pada)',
    );

    await db.execute('''
      CREATE TABLE $tTambahan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga REAL NOT NULL DEFAULT 0,
        aktif INTEGER NOT NULL DEFAULT 1,
        dibuat_pada INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tTambahanItemPenjualan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_item_penjualan INTEGER NOT NULL,
        id_tambahan INTEGER,
        nama TEXT NOT NULL,
        harga REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (id_item_penjualan) REFERENCES $tItemPenjualan(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_tambahan_item_penjualan_item ON $tTambahanItemPenjualan(id_item_penjualan)',
    );
  }

  Future<bool> _tabelAda(DatabaseExecutor db, String nama) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [nama],
    );
    return rows.isNotEmpty;
  }

  Future<void> _migrasiKeIndonesia(Database db) async {
    final sudahBaru = await _tabelAda(db, tProduk);
    final adaLama = await _tabelAda(db, 'products');
    if (sudahBaru) {
      await _migrasiPin(db);
      return;
    }
    if (!adaLama) {
      await _buatSkema(db);
      await _isiProdukAwal(db);
      await _isiPenggunaAwal(db);
      return;
    }

    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      await _buatSkema(txn);

      if (await _tabelAda(txn, 'products')) {
        await txn.execute('''
          INSERT INTO $tProduk (id, nama, harga, stok, aktif, dibuat_pada)
          SELECT id, name, price, stock, active, created_at FROM products
        ''');
      }
      if (await _tabelAda(txn, 'transactions')) {
        final cols = await txn.rawQuery("PRAGMA table_info(transactions)");
        final punyaIdPengguna = cols.any((c) => c['name'] == 'user_id');
        final kolomIdPengguna = punyaIdPengguna ? 'user_id' : 'NULL';
        await txn.execute('''
          INSERT INTO $tTransaksi
            (id, nomor, metode_pembayaran, total, dibayar, kembalian, id_pengguna, dibuat_pada)
          SELECT id, number, payment_method, total, payed, change, $kolomIdPengguna, created_at
          FROM transactions
        ''');
      }
      if (await _tabelAda(txn, 'sale_items')) {
        await txn.execute('''
          INSERT INTO $tItemPenjualan
            (id, id_transaksi, id_produk, nama, harga, jumlah, subtotal)
          SELECT id, transaction_id, product_id, name, price, qty, subtotal FROM sale_items
        ''');
      }
      if (await _tabelAda(txn, 'cash_entries')) {
        await txn.execute('''
          INSERT INTO $tCatatanKas (id, jenis, kategori, jumlah, keterangan, dibuat_pada)
          SELECT id, kind, category, amount, note, created_at FROM cash_entries
        ''');
      }
      if (await _tabelAda(txn, 'users')) {
        final cols = await txn.rawQuery("PRAGMA table_info(users)");
        final punyaTerakhir = cols.any((c) => c['name'] == 'last_login_at');
        final kolomTerakhir = punyaTerakhir ? 'last_login_at' : 'NULL';
        await txn.execute('''
          INSERT INTO $tPengguna
            (id, nama_pengguna, pin, nama_lengkap, peran, aktif, dibuat_pada, terakhir_masuk_pada)
          SELECT id, username, pin, full_name, role, active, created_at, $kolomTerakhir FROM users
        ''');
      }
      if (await _tabelAda(txn, 'stock_adjustments')) {
        await txn.execute('''
          INSERT INTO $tPenyesuaianStok
            (id, id_produk, nama_produk, perubahan_jumlah, alasan, catatan, nilai_kerugian, dibuat_pada)
          SELECT id, product_id, product_name, qty_change, reason, note, loss_amount, created_at
          FROM stock_adjustments
        ''');
      }
      if (await _tabelAda(txn, 'modifiers')) {
        await txn.execute('''
          INSERT INTO $tTambahan (id, nama, harga, aktif, dibuat_pada)
          SELECT id, name, price, active, created_at FROM modifiers
        ''');
      }
      if (await _tabelAda(txn, 'sale_item_modifiers')) {
        await txn.execute('''
          INSERT INTO $tTambahanItemPenjualan (id, id_item_penjualan, id_tambahan, nama, harga)
          SELECT id, sale_item_id, modifier_id, name, price FROM sale_item_modifiers
        ''');
      }

      // Hapus tabel lama (urutan aman untuk FK)
      for (final t in [
        'sale_item_modifiers',
        'sale_items',
        'transactions',
        'cash_entries',
        'stock_adjustments',
        'products',
        'modifiers',
        'users',
      ]) {
        if (await _tabelAda(txn, t)) {
          await txn.execute('DROP TABLE $t');
        }
      }
      await txn.execute('PRAGMA foreign_keys = ON');
    });
    await _migrasiPin(db);
  }

  Future<void> _isiTambahanAwal(DatabaseExecutor db) async {
    final sekarang = DateTime.now().millisecondsSinceEpoch;
    final ada = await db.query(tTambahan, limit: 1);
    if (ada.isNotEmpty) return;
    const dataAwal = [
      (nama: 'Stroberi', harga: 5000.0),
      (nama: 'Coklat', harga: 5000.0),
      (nama: 'Milo', harga: 5000.0),
      (nama: 'Taro', harga: 5000.0),
      (nama: 'Tiramisu', harga: 6000.0),
      (nama: 'Matcha', harga: 6000.0),
    ];
    for (final m in dataAwal) {
      await db.insert(tTambahan, {
        'nama': m.nama,
        'harga': m.harga,
        'aktif': 1,
        'dibuat_pada': sekarang,
      });
    }
  }

  Future<void> _isiPenggunaAwal(DatabaseExecutor db) async {
    final sekarang = DateTime.now().millisecondsSinceEpoch;
    final ada = await db.query(tPengguna, limit: 1);
    if (ada.isNotEmpty) return;
    await db.insert(tPengguna, {
      'nama_pengguna': 'admin',
      'pin': hashPin('123456'),
      'nama_lengkap': 'Admin',
      'peran': 'admin',
      'aktif': 1,
      'dibuat_pada': sekarang,
    });
    await db.insert(tPengguna, {
      'nama_pengguna': 'kasir',
      'pin': hashPin('123456'),
      'nama_lengkap': 'Kasir',
      'peran': 'kasir',
      'aktif': 1,
      'dibuat_pada': sekarang,
    });
  }

  /// Mengubah PIN lama yang masih teks biasa menjadi hash.
  Future<void> _migrasiPin(DatabaseExecutor db) async {
    final rows = await db.query(tPengguna, columns: ['id', 'pin']);
    for (final row in rows) {
      final pin = row['pin'] as String?;
      if (pin == null || pinSudahDihash(pin)) continue;
      await db.update(
        tPengguna,
        {'pin': hashPin(pin)},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> _isiProdukAwal(DatabaseExecutor db) async {
    final sekarang = DateTime.now().millisecondsSinceEpoch;
    final ada = await db.query(tProduk, limit: 1);
    if (ada.isNotEmpty) {
      await _isiTambahanAwal(db);
      return;
    }
    await db.insert(tProduk, {
      'nama': 'Pisang Goreng',
      'harga': 10000.0,
      'stok': 100,
      'aktif': 1,
      'dibuat_pada': sekarang,
    });
    await _isiTambahanAwal(db);
  }

  /// Menghapus seluruh data transaksi, keuangan, dan produk, lalu mengisi
  /// kembali produk contoh. Pengaturan toko tidak ikut dihapus.
  Future<void> resetData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tTambahanItemPenjualan);
      await txn.delete(tItemPenjualan);
      await txn.delete(tTransaksi);
      await txn.delete(tCatatanKas);
      await txn.delete(tPenyesuaianStok);
      await txn.delete(tProduk);
      await _isiProdukAwal(txn);
    });
  }
}
