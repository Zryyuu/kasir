import 'package:flutter/foundation.dart';

import '../data/basis_data.dart';
import '../model/tambahan.dart';

class PenyediaTambahan extends ChangeNotifier {
  PenyediaTambahan(this._basisData);

  final BasisData _basisData;

  List<Tambahan> _daftarTambahan = [];
  bool _memuat = false;

  List<Tambahan> get daftarTambahan => List.unmodifiable(_daftarTambahan);
  List<Tambahan> get tambahanAktif =>
      _daftarTambahan.where((m) => m.aktif).toList();
  bool get memuat => _memuat;

  Future<void> load() async {
    _memuat = true;
    notifyListeners();
    final db = await _basisData.database;
    final rows = await db.query(BasisData.tTambahan, orderBy: 'id ASC');
    _daftarTambahan = rows.map(Tambahan.dariPeta).toList();
    _memuat = false;
    notifyListeners();
  }
}
