import 'package:flutter/foundation.dart';

import '../model/item_keranjang.dart';
import '../model/produk.dart';

class PenyediaKeranjang extends ChangeNotifier {
  final List<ItemKeranjang> _daftarItem = [];

  List<ItemKeranjang> get items => List.unmodifiable(_daftarItem);

  bool get isEmpty => _daftarItem.isEmpty;

  int get totalJumlah => _daftarItem.fold(0, (sum, barang) => sum + barang.jumlah);

  double get total => _daftarItem.fold(0, (sum, barang) => sum + barang.subtotal);

  /// Menambahkan produk ke keranjang dengan modifier.
  String? tambahDenganTambahan(
    Produk produk,
    List<TambahanItemKeranjang> daftarTambahan,
  ) {
    if (produk.stok <= 0) {
      return 'Stok ${produk.nama} sedang habis.';
    }

    // For pisang goreng with modifiers, treat as different line if modifiers differ
    final key = daftarTambahan.map((m) => m.nama).join('|');
    final index = _daftarItem.indexWhere((barang) {
      if (barang.idProduk != produk.id) return false;
      final k2 = barang.daftarTambahan.map((m) => m.nama).join('|');
      return k2 == key;
    });
    if (index >= 0) {
      final current = _daftarItem[index];
      if (current.jumlah >= produk.stok) {
        return 'Stok ${produk.nama} tinggal ${produk.stok} porsi.';
      }
      _daftarItem[index] = current.salinDengan(
        jumlah: current.jumlah + 1,
        stok: produk.stok,
      );
    } else {
      _daftarItem.add(
        ItemKeranjang(
          idProduk: produk.id!,
          nama: produk.nama,
          harga: produk.harga,
          jumlah: 1,
          stok: produk.stok,
          daftarTambahan: List.from(daftarTambahan),
        ),
      );
    }
    notifyListeners();
    return null;
  }

  /// Menambahkan produk ke keranjang. Mengembalikan pesan error jika gagal.
  String? tambah(Produk produk) {
    return tambahDenganTambahan(produk, const []);
  }

  void tambahJumlah(int index) {
    if (index < 0 || index >= _daftarItem.length) return;
    final barang = _daftarItem[index];
    if (barang.jumlah >= barang.stok) return;
    _daftarItem[index] = barang.salinDengan(jumlah: barang.jumlah + 1);
    notifyListeners();
  }

  void kurangiJumlah(int index) {
    if (index < 0 || index >= _daftarItem.length) return;
    final barang = _daftarItem[index];
    if (barang.jumlah <= 1) {
      _daftarItem.removeAt(index);
    } else {
      _daftarItem[index] = barang.salinDengan(jumlah: barang.jumlah - 1);
    }
    notifyListeners();
  }

  void hapusPada(int index) {
    if (index < 0 || index >= _daftarItem.length) return;
    _daftarItem.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_daftarItem.isEmpty) return;
    _daftarItem.clear();
    notifyListeners();
  }
}

