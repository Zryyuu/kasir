import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _prefiks = 'v1';

/// Membuat hash PIN dengan salt acak.
///
/// Format tersimpan: `v1:<salt>:<hash>`. Salt dan hash memakai base64url/hex
/// sehingga aman disimpan di kolom TEXT.
String hashPin(String pin) {
  final salt = _buatSalt();
  return '$_prefiks:$salt:${_hitung(pin, salt)}';
}

/// Memeriksa PIN terhadap nilai tersimpan.
///
/// Mendukung data lama yang masih berupa PIN plaintext agar pengguna tidak
/// terkunci. Setelah login berhasil, pemanggil sebaiknya menyimpan ulang
/// dengan [hashPin].
bool verifikasiPin(String tersimpan, String pin) {
  final bagian = tersimpan.split(':');
  if (bagian.length != 3 || bagian[0] != _prefiks) {
    return tersimpan == pin;
  }
  return _samaAman(_hitung(pin, bagian[1]), bagian[2]);
}

/// Apakah PIN tersimpan sudah memakai format hash terbaru.
bool pinSudahDihash(String tersimpan) => tersimpan.startsWith('$_prefiks:');

String _hitung(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

String _buatSalt() {
  final acak = Random.secure();
  final bytes = List<int>.generate(16, (_) => acak.nextInt(256));
  return base64Url.encode(bytes);
}

bool _samaAman(String a, String b) {
  if (a.length != b.length) return false;
  var hasil = 0;
  for (var i = 0; i < a.length; i++) {
    hasil |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return hasil == 0;
}
