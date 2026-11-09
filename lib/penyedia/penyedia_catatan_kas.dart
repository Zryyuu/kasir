import 'package:flutter/foundation.dart';

import '../data/basis_data.dart';
import '../model/catatan_kas.dart';

class PenyediaCatatanKas extends ChangeNotifier {
  PenyediaCatatanKas(this._basisData);

  final BasisData _basisData;

  List<CatatanKas> _daftarCatatan = [];
  bool _memuat = false;

  List<CatatanKas> get daftarCatatan => List.unmodifiable(_daftarCatatan);
  bool get memuat => _memuat;

  Future<void> load() async {
    _memuat = true;
    notifyListeners();
    final db = await _basisData.database;
    final rows = await db.query(BasisData.tCatatanKas, orderBy: 'dibuat_pada DESC');
    _daftarCatatan = rows.map(CatatanKas.dariPeta).toList();
    _memuat = false;
    notifyListeners();
  }

  Future<void> tambah({
    required JenisCatatanKas jenis,
    required String kategori,
    required double jumlah,
    String? keterangan,
    required DateTime dibuatPada,
  }) async {
    final db = await _basisData.database;
    await db.insert(BasisData.tCatatanKas, {
      'jenis': jenis.nilai,
      'kategori': kategori,
      'jumlah': jumlah,
      'keterangan': (keterangan ?? '').trim().isEmpty ? null : keterangan!.trim(),
      'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
    });
    await load();
  }

  Future<void> perbarui(CatatanKas catatan) async {
    final db = await _basisData.database;
    await db.update(
      BasisData.tCatatanKas,
      catatan.kePeta()..remove('id'),
      where: 'id = ?',
      whereArgs: [catatan.id],
    );
    await load();
  }

  Future<void> hapus(int id) async {
    final db = await _basisData.database;
    await db.delete(BasisData.tCatatanKas, where: 'id = ?', whereArgs: [id]);
    await load();
  }

  List<CatatanKas> catatanUntukBulan(DateTime bulan) {
    return _daftarCatatan
        .where(
          (catatan) =>
              catatan.dibuatPada.year == bulan.year &&
              catatan.dibuatPada.month == bulan.month,
        )
        .toList();
  }

  List<CatatanKas> catatanAntara(DateTime awal, DateTime akhir) {
    final awalMs =
        DateTime(awal.year, awal.month, awal.day).millisecondsSinceEpoch;
    final akhirMs = DateTime(
      akhir.year,
      akhir.month,
      akhir.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    return _daftarCatatan
        .where(
          (catatan) =>
              catatan.dibuatPada.millisecondsSinceEpoch >= awalMs &&
              catatan.dibuatPada.millisecondsSinceEpoch <= akhirMs,
        )
        .toList();
  }

  double totalUntuk(JenisCatatanKas jenis, DateTime awal, DateTime akhir) {
    return catatanAntara(awal, akhir)
        .where((catatan) => catatan.jenis == jenis)
        .fold(0, (sum, catatan) => sum + catatan.jumlah);
  }

  double totalUntukBulan(JenisCatatanKas jenis, DateTime bulan) {
    return catatanUntukBulan(bulan)
        .where((catatan) => catatan.jenis == jenis)
        .fold(0, (sum, catatan) => sum + catatan.jumlah);
  }

  double totalHariIni(JenisCatatanKas jenis) {
    final sekarang = DateTime.now();
    return totalUntuk(jenis, sekarang, sekarang);
  }

  Map<String, double> totalPerKategori(
    JenisCatatanKas jenis,
    DateTime awal,
    DateTime akhir,
  ) {
    final peta = <String, double>{};
    for (final catatan in catatanAntara(awal, akhir)) {
      if (catatan.jenis != jenis) continue;
      peta.update(
        catatan.kategori,
        (nilai) => nilai + catatan.jumlah,
        ifAbsent: () => catatan.jumlah,
      );
    }
    return peta;
  }
}
