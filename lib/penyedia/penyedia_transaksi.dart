import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/basis_data.dart';
import '../model/item_penjualan.dart';
import '../model/transaksi_penjualan.dart';

class RingkasanPenjualan {
  final double penjualan;
  final int jumlahTransaksi;
  final int jumlah;

  const RingkasanPenjualan(
      {this.penjualan = 0, this.jumlahTransaksi = 0, this.jumlah = 0});
}

class ProdukTerlaris {
  final String nama;
  final int jumlah;
  final double pendapatan;

  const ProdukTerlaris({
    required this.nama,
    required this.jumlah,
    required this.pendapatan,
  });
}

class PenyediaTransaksi extends ChangeNotifier {
  PenyediaTransaksi(this._basisData);

  final BasisData _basisData;

  List<TransaksiPenjualan> _terbaru = [];
  RingkasanPenjualan _ringkasanHariIni = const RingkasanPenjualan();
  bool _memuat = false;

  List<TransaksiPenjualan> get terbaru => List.unmodifiable(_terbaru);
  RingkasanPenjualan get ringkasanHariIni => _ringkasanHariIni;
  bool get memuat => _memuat;

  static DateTime _awalHari(DateTime nilai) =>
      DateTime(nilai.year, nilai.month, nilai.day);

  static DateTime _akhirHari(DateTime nilai) =>
      DateTime(nilai.year, nilai.month, nilai.day, 23, 59, 59, 999);

  Future<void> muatTerbaru({int limit = 50}) async {
    _memuat = true;
    notifyListeners();

    final db = await _basisData.database;
    final rows = await db.query(
      BasisData.tTransaksi,
      orderBy: 'dibuat_pada DESC',
      limit: limit,
    );
    final itemPerTransaksi = await _itemUntuk(
      db,
      rows.map((row) => row['id'] as int).toList(),
    );
    final namaKasir = await _namaKasirUntuk(db, rows);
    _terbaru = rows
        .map((row) {
          final idKasir = (row['id_pengguna'] as num?)?.toInt();
          return TransaksiPenjualan.dariPeta(
            row,
            items: itemPerTransaksi[row['id'] as int] ?? const [],
            namaKasir: idKasir == null ? null : namaKasir[idKasir],
          );
        })
        .toList();

    final sekarang = DateTime.now();
    _ringkasanHariIni = await ringkasanUntuk(sekarang, sekarang);
    _memuat = false;
    notifyListeners();
  }

  Future<RingkasanPenjualan> ringkasanUntuk(
      DateTime awal, DateTime akhir) async {
    final db = await _basisData.database;
    final awalMs = _awalHari(awal).millisecondsSinceEpoch;
    final akhirMs = _akhirHari(akhir).millisecondsSinceEpoch;

    final barisPenjualan = await db.rawQuery(
      '''
      SELECT COUNT(*) AS jumlah_transaksi, COALESCE(SUM(total), 0) AS penjualan
      FROM ${BasisData.tTransaksi}
      WHERE dibuat_pada BETWEEN ? AND ?
      ''',
      [awalMs, akhirMs],
    );
    final barisJumlah = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(ip.jumlah), 0) AS jumlah
      FROM ${BasisData.tItemPenjualan} ip
      JOIN ${BasisData.tTransaksi} t ON t.id = ip.id_transaksi
      WHERE t.dibuat_pada BETWEEN ? AND ?
      ''',
      [awalMs, akhirMs],
    );

    final penjualan = barisPenjualan.first;
    final jumlah = barisJumlah.first;
    return RingkasanPenjualan(
      penjualan: (penjualan['penjualan'] as num?)?.toDouble() ?? 0,
      jumlahTransaksi: (penjualan['jumlah_transaksi'] as num?)?.toInt() ?? 0,
      jumlah: (jumlah['jumlah'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<TransaksiPenjualan>> berdasarkanRentang(
    DateTime awal,
    DateTime akhir, {
    String kataKunci = '',
    String? metodePembayaran,
  }) async {
    final db = await _basisData.database;
    final awalMs = _awalHari(awal).millisecondsSinceEpoch;
    final akhirMs = _akhirHari(akhir).millisecondsSinceEpoch;

    final kondisi = <String>['dibuat_pada BETWEEN ? AND ?'];
    final argumen = <Object?>[awalMs, akhirMs];

    final kunciBersih = kataKunci.trim();
    if (kunciBersih.isNotEmpty) {
      kondisi.add('nomor LIKE ?');
      argumen.add('%$kunciBersih%');
    }
    if (metodePembayaran != null && metodePembayaran.isNotEmpty) {
      kondisi.add('metode_pembayaran = ?');
      argumen.add(metodePembayaran);
    }

    final rows = await db.query(
      BasisData.tTransaksi,
      where: kondisi.join(' AND '),
      whereArgs: argumen,
      orderBy: 'dibuat_pada DESC',
    );
    final itemPerTransaksi = await _itemUntuk(
      db,
      rows.map((row) => row['id'] as int).toList(),
    );
    final namaKasir = await _namaKasirUntuk(db, rows);
    return rows
        .map((row) {
          final idKasir = (row['id_pengguna'] as num?)?.toInt();
          return TransaksiPenjualan.dariPeta(
            row,
            items: itemPerTransaksi[row['id'] as int] ?? const [],
            namaKasir: idKasir == null ? null : namaKasir[idKasir],
          );
        })
        .toList();
  }

  Future<List<ProdukTerlaris>> produkTerlaris(
    DateTime awal,
    DateTime akhir, {
    int limit = 5,
  }) async {
    final db = await _basisData.database;
    final awalMs = _awalHari(awal).millisecondsSinceEpoch;
    final akhirMs = _akhirHari(akhir).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      '''
      SELECT ip.nama, SUM(ip.jumlah) AS jumlah, SUM(ip.subtotal) AS pendapatan
      FROM ${BasisData.tItemPenjualan} ip
      JOIN ${BasisData.tTransaksi} t ON t.id = ip.id_transaksi
      WHERE t.dibuat_pada BETWEEN ? AND ?
      GROUP BY ip.nama
      ORDER BY jumlah DESC, pendapatan DESC
      LIMIT ?
      ''',
      [awalMs, akhirMs, limit],
    );
    return rows
        .map(
          (row) => ProdukTerlaris(
            nama: row['nama'] as String,
            jumlah: (row['jumlah'] as num?)?.toInt() ?? 0,
            pendapatan: (row['pendapatan'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  Future<Map<int, List<ItemPenjualan>>> _itemUntuk(
    Database db,
    List<int> idTransaksiList,
  ) async {
    if (idTransaksiList.isEmpty) return {};
    final penanda = List.filled(idTransaksiList.length, '?').join(', ');
    final rows = await db.query(
      BasisData.tItemPenjualan,
      where: 'id_transaksi IN ($penanda)',
      whereArgs: idTransaksiList,
    );
    if (rows.isEmpty) return {};

    final idItem = rows.map((row) => row['id'] as int).toList();
    final penandaItem = List.filled(idItem.length, '?').join(', ');
    final barisTambahan = await db.query(
      BasisData.tTambahanItemPenjualan,
      where: 'id_item_penjualan IN ($penandaItem)',
      whereArgs: idItem,
    );
    final tambahanPerItem = <int, List<TambahanPenjualan>>{};
    for (final row in barisTambahan) {
      final id = row['id_item_penjualan'] as int;
      tambahanPerItem
          .putIfAbsent(id, () => [])
          .add(TambahanPenjualan.dariPeta(row));
    }

    final peta = <int, List<ItemPenjualan>>{};
    for (final row in rows) {
      final idTransaksi = row['id_transaksi'] as int;
      final id = row['id'] as int;
      peta.putIfAbsent(idTransaksi, () => []).add(
            ItemPenjualan.dariPeta(
              row,
              daftarTambahan: tambahanPerItem[id] ?? const [],
            ),
          );
    }
    return peta;
  }

  Future<Map<int, String>> _namaKasirUntuk(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    final ids = rows
        .map((row) => (row['id_pengguna'] as num?)?.toInt())
        .whereType<int>()
        .toSet()
        .toList();
    if (ids.isEmpty) return {};
    final penanda = List.filled(ids.length, '?').join(', ');
    final barisPengguna = await db.query(
      BasisData.tPengguna,
      columns: ['id', 'nama_lengkap'],
      where: 'id IN ($penanda)',
      whereArgs: ids,
    );
    return {
      for (final row in barisPengguna)
        row['id'] as int: row['nama_lengkap'] as String,
    };
  }
}
