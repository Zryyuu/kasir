import 'package:flutter_test/flutter_test.dart';
import 'package:sinarku/model/item_penjualan.dart';

void main() {
  test('nama tampilan item menyertakan topping', () {
    const item = ItemPenjualan(
      idProduk: 1,
      nama: 'Pisang Goreng',
      harga: 15000,
      jumlah: 1,
      subtotal: 15000,
      daftarTambahan: [TambahanPenjualan(nama: 'Coklat', harga: 5000)],
    );
    expect(item.namaTampilan, 'Pisang Goreng (Coklat)');
  });

  test('dariPeta membaca id dan topping', () {
    final item = ItemPenjualan.dariPeta(
      {
        'id': 7,
        'id_produk': 1,
        'nama': 'Pisang Goreng',
        'harga': 15000,
        'jumlah': 2,
        'subtotal': 30000,
      },
      daftarTambahan: const [
        TambahanPenjualan(nama: 'Coklat', harga: 5000),
      ],
    );
    expect(item.id, 7);
    expect(item.jumlah, 2);
    expect(item.daftarTambahan.single.nama, 'Coklat');
  });
}
