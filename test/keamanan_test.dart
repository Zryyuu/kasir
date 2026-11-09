import 'package:flutter_test/flutter_test.dart';
import 'package:sinarku/inti/keamanan.dart';

void main() {
  test('hash PIN tidak menyimpan plaintext', () {
    final hash = hashPin('123456');
    expect(hash.startsWith('v1:'), isTrue);
    expect(hash.contains('123456'), isFalse);
    expect(pinSudahDihash(hash), isTrue);
  });

  test('verifikasi PIN benar dan salah', () {
    final hash = hashPin('123456');
    expect(verifikasiPin(hash, '123456'), isTrue);
    expect(verifikasiPin(hash, '654321'), isFalse);
  });

  test('PIN plaintext lama tetap bisa diverifikasi', () {
    expect(verifikasiPin('123456', '123456'), isTrue);
    expect(verifikasiPin('123456', '000000'), isFalse);
    expect(pinSudahDihash('123456'), isFalse);
  });
}
