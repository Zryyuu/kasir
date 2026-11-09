import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/basis_data.dart';
import '../inti/keamanan.dart';
import '../model/pengguna.dart';

class PenyediaAuth extends ChangeNotifier {
  PenyediaAuth(this._basisData);

  final BasisData _basisData;

  Pengguna? _penggunaSaatIni;
  String? _galat;
  bool _memuat = false;

  Pengguna? get penggunaSaatIni => _penggunaSaatIni;
  bool get sudahMasuk => _penggunaSaatIni != null;
  bool get adalahAdmin => _penggunaSaatIni?.adalahAdmin ?? false;
  String? get galat => _galat;
  bool get memuat => _memuat;

  Future<List<Pengguna>> penggunaAktif() async {
    final db = await _basisData.database;
    final rows = await db.query(
      BasisData.tPengguna,
      columns: ['id', 'nama_pengguna', 'nama_lengkap', 'peran', 'aktif'],
      where: 'aktif = 1',
      orderBy: 'peran DESC, nama_lengkap ASC',
    );
    return rows.map(Pengguna.dariPeta).toList();
  }

  Future<bool> masuk(String namaPengguna, String pin) async {
    _memuat = true;
    _galat = null;
    notifyListeners();
    try {
      final db = await _basisData.database;
      final rows = await db.query(
        BasisData.tPengguna,
        where: 'nama_pengguna = ? AND aktif = 1',
        whereArgs: [namaPengguna.trim()],
        limit: 1,
      );
      if (rows.isEmpty) {
        _galat = 'PIN salah atau pengguna tidak aktif.';
        _memuat = false;
        notifyListeners();
        return false;
      }

      final data = Map<String, Object?>.from(rows.first);
      final pinTersimpan = data['pin'] as String? ?? '';
      if (!verifikasiPin(pinTersimpan, pin)) {
        _galat = 'PIN salah atau pengguna tidak aktif.';
        _memuat = false;
        notifyListeners();
        return false;
      }

      if (!pinSudahDihash(pinTersimpan)) {
        final pinBaru = hashPin(pin);
        await db.update(
          BasisData.tPengguna,
          {'pin': pinBaru},
          where: 'id = ?',
          whereArgs: [data['id']],
        );
        data['pin'] = pinBaru;
      }

      _penggunaSaatIni = Pengguna.dariPeta(data);
      await db.update(
        BasisData.tPengguna,
        {'terakhir_masuk_pada': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [_penggunaSaatIni!.id],
      );
      _memuat = false;
      notifyListeners();
      return true;
    } catch (e) {
      _galat = 'Gagal masuk: $e';
      _memuat = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Pengguna>> semuaPengguna() async {
    final db = await _basisData.database;
    final rows = await db.query(
      BasisData.tPengguna,
      columns: ['id', 'nama_pengguna', 'nama_lengkap', 'peran', 'aktif'],
      orderBy: 'aktif DESC, peran DESC, nama_lengkap ASC',
    );
    return rows.map(Pengguna.dariPeta).toList();
  }

  Future<String?> simpanPengguna({
    int? id,
    required String namaPengguna,
    required String namaLengkap,
    required String peran,
    String? pin,
    bool aktif = true,
  }) async {
    final namaPenggunaBersih = namaPengguna.trim();
    final nama = namaLengkap.trim();
    final pinBaru = pin?.trim() ?? '';

    if (namaPenggunaBersih.isEmpty) return 'Nama pengguna wajib diisi.';
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(namaPenggunaBersih)) {
      return 'Nama pengguna hanya boleh huruf, angka, titik, dan garis bawah.';
    }
    if (nama.isEmpty) return 'Nama lengkap wajib diisi.';
    if (peran != 'admin' && peran != 'kasir') return 'Peran tidak dikenal.';
    if (id == null && pinBaru.isEmpty) return 'PIN wajib diisi.';
    if (pinBaru.isNotEmpty) {
      if (!RegExp(r'^\d{4,}$').hasMatch(pinBaru)) {
        return 'PIN minimal 4 digit angka.';
      }
    }

    final db = await _basisData.database;
    if (id != null) {
      final rows = await db.query(
        BasisData.tPengguna,
        columns: ['peran', 'aktif'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return 'Pengguna tidak ditemukan.';
      final peranLama = rows.first['peran'] as String;
      final aktifLama = (rows.first['aktif'] as num) == 1;
      final tetapAdminAktif = peran == 'admin' && aktif;
      if (peranLama == 'admin' && aktifLama && !tetapAdminAktif) {
        final adminLain = await db.rawQuery(
          "SELECT COUNT(*) AS total FROM ${BasisData.tPengguna} "
          "WHERE peran = 'admin' AND aktif = 1 AND id != ?",
          [id],
        );
        final total = (adminLain.first['total'] as num?)?.toInt() ?? 0;
        if (total == 0) return 'Minimal harus ada satu admin aktif.';
      }
      if (id == _penggunaSaatIni?.id) {
        if (!aktif) return 'Tidak bisa menonaktifkan akun yang sedang dipakai.';
        if (_penggunaSaatIni!.adalahAdmin && peran != 'admin') {
          return 'Tidak bisa mengubah peran akun yang sedang dipakai.';
        }
      }
    }

    final data = <String, Object?>{
      'nama_pengguna': namaPenggunaBersih,
      'nama_lengkap': nama,
      'peran': peran,
      'aktif': aktif ? 1 : 0,
    };
    if (pinBaru.isNotEmpty) data['pin'] = hashPin(pinBaru);

    try {
      if (id == null) {
        data['dibuat_pada'] = DateTime.now().millisecondsSinceEpoch;
        await db.insert(BasisData.tPengguna, data);
      } else {
        await db.update(BasisData.tPengguna, data, where: 'id = ?', whereArgs: [id]);
      }
      notifyListeners();
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return 'Nama pengguna sudah dipakai.';
      return 'Gagal menyimpan pengguna: $e';
    } catch (e) {
      return 'Gagal menyimpan pengguna: $e';
    }
  }

  void bersihkanGalat() {
    if (_galat == null) return;
    _galat = null;
    notifyListeners();
  }

  void keluar() {
    _penggunaSaatIni = null;
    _galat = null;
    _memuat = false;
    notifyListeners();
  }
}
