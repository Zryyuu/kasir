import 'package:flutter/foundation.dart';

import '../data/basis_data.dart';
import '../model/produk.dart';

class PenyediaKatalog extends ChangeNotifier {
  PenyediaKatalog(this._basisData);

  final BasisData _basisData;

  List<Produk> _daftarProduk = [];
  bool _memuat = false;

  List<Produk> get daftarProduk => List.unmodifiable(_daftarProduk);
  List<Produk> get produkAktif =>
      _daftarProduk.where((produk) => produk.aktif).toList(growable: false);
  bool get memuat => _memuat;

  Produk? produkBerdasarkanId(int id) {
    for (final produk in _daftarProduk) {
      if (produk.id == id) return produk;
    }
    return null;
  }

  Future<void> load() async {
    _memuat = true;
    notifyListeners();
    final db = await _basisData.database;
    final rows = await db.query(
      BasisData.tProduk,
      orderBy: 'aktif DESC, nama COLLATE NOCASE ASC',
    );
    _daftarProduk = rows.map(Produk.dariPeta).toList();
    _memuat = false;
    notifyListeners();
  }

  Future<void> tambahProduk({
    required String nama,
    required double harga,
    required int stok,
  }) async {
    final db = await _basisData.database;
    final namaBersih = nama.trim();
    final stokAwal = stok < 0 ? 0 : stok;
    final sekarang = DateTime.now();
    await db.transaction((txn) async {
      final idProduk = await txn.insert(BasisData.tProduk, {
        'nama': namaBersih,
        'harga': harga,
        'stok': stokAwal,
        'aktif': 1,
        'dibuat_pada': sekarang.millisecondsSinceEpoch,
      });
      if (stokAwal > 0) {
        await txn.insert(BasisData.tPenyesuaianStok, {
          'id_produk': idProduk,
          'nama_produk': namaBersih,
          'perubahan_jumlah': stokAwal,
          'alasan': 'Stok awal',
          'catatan': null,
          'nilai_kerugian': 0,
          'dibuat_pada': sekarang.millisecondsSinceEpoch,
        });
      }
    });
    await load();
  }

  Future<void> perbaruiProduk(Produk produk) async {
    final db = await _basisData.database;
    await db.update(
      BasisData.tProduk,
      {
        'nama': produk.nama.trim(),
        'harga': produk.harga,
        'aktif': produk.aktif ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [produk.id],
    );
    await load();
  }

  Future<void> aturAktif(int idProduk, bool aktif) async {
    final db = await _basisData.database;
    await db.update(
      BasisData.tProduk,
      {'aktif': aktif ? 1 : 0},
      where: 'id = ?',
      whereArgs: [idProduk],
    );
    await load();
  }
}
