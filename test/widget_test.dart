import 'package:flutter_test/flutter_test.dart';
import 'package:sinarku/inti/pemformat.dart';

void main() {
  test('format rupiah memakai pemisah ribuan', () {
    expect(Uang.format(20000), 'Rp20.000');
    expect(Uang.format(1500), 'Rp1.500');
    expect(Uang.format(-5000), '-Rp5.000');
    expect(Uang.polos(1250000), '1.250.000');
  });

  test('parse nominal dari teks berformat', () {
    expect(Uang.urai('20.000'), 20000);
    expect(Uang.urai('Rp 1.250.000'), 1250000);
    expect(Uang.urai(''), 0);
  });
}
