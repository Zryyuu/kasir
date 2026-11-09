import '../inti/pemformat.dart';
import '../data/basis_data.dart';
import '../model/item_keranjang.dart';
import '../model/item_penjualan.dart';
import '../model/transaksi_penjualan.dart';

class PengecualianPenjualan implements Exception {
  final String pesan;
  const PengecualianPenjualan(this.pesan);

  @override
  String toString() => pesan;
}

/// Menyimpan transaksi penjualan secara atomik.
///
/// Transaksi, detail item, dan pengurangan stok ditulis dalam satu transaksi
/// basis data. Jika stok tidak cukup atau ada kegagalan lain, semua dibatalkan.
class LayananPenjualan {
  LayananPenjualan(this._basisData);

  final BasisData _basisData;

  Future<TransaksiPenjualan> checkout({
    required List<ItemKeranjang> items,
    required String metodePembayaran,
    required double dibayar,
    int? idPengguna,
    String? namaKasir,
  }) async {
    if (items.isEmpty) {
      throw const PengecualianPenjualan('Keranjang masih kosong.');
    }
    if (metodePembayaran != kPembayaranTunai &&
        metodePembayaran != kPembayaranQris) {
      throw const PengecualianPenjualan('Metode pembayaran tidak dikenal.');
    }

    final total = items.fold<double>(0, (sum, barang) => sum + barang.subtotal);
    final adalahTunai = metodePembayaran == kPembayaranTunai;
    if (adalahTunai && dibayar < total) {
      throw const PengecualianPenjualan(
          'Uang diterima kurang dari total belanja.');
    }

    final sekarang = DateTime.now();
    final db = await _basisData.database;

    return db.transaction((txn) async {
      final awalHari = DateTime(
        sekarang.year,
        sekarang.month,
        sekarang.day,
      ).millisecondsSinceEpoch;
      final akhirHari = DateTime(
        sekarang.year,
        sekarang.month,
        sekarang.day,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch;
      final barisNomor = await txn.rawQuery(
        'SELECT nomor FROM ${BasisData.tTransaksi} WHERE dibuat_pada BETWEEN ? AND ?',
        [awalHari, akhirHari],
      );
      var urutanTerakhir = 0;
      for (final baris in barisNomor) {
        final nomorLama = baris['nomor'] as String? ?? '';
        final urutan = int.tryParse(nomorLama.split('-').last);
        if (urutan != null && urutan > urutanTerakhir) {
          urutanTerakhir = urutan;
        }
      }
      final urutan = urutanTerakhir + 1;
      final nomor =
          'PJS-${Tanggal.capStruk(sekarang)}-${urutan.toString().padLeft(3, '0')}';

      final kebutuhanStok = <int, int>{};
      final namaProduk = <int, String>{};
      for (final barang in items) {
        kebutuhanStok[barang.idProduk] =
            (kebutuhanStok[barang.idProduk] ?? 0) + barang.jumlah;
        namaProduk[barang.idProduk] = barang.nama;
      }

      for (final entri in kebutuhanStok.entries) {
        final barisStok = await txn.query(
          BasisData.tProduk,
          columns: ['nama', 'stok'],
          where: 'id = ?',
          whereArgs: [entri.key],
          limit: 1,
        );
        final stokSekarang = barisStok.isEmpty
            ? 0
            : (barisStok.first['stok'] as num).toInt();
        if (stokSekarang < entri.value) {
          final nama = barisStok.isEmpty
              ? namaProduk[entri.key] ?? 'Produk'
              : barisStok.first['nama'] as String;
          throw PengecualianPenjualan(
            'Stok $nama tidak cukup. Tersisa $stokSekarang porsi.',
          );
        }
      }

      final idTransaksi = await txn.insert(BasisData.tTransaksi, {
        'nomor': nomor,
        'metode_pembayaran': metodePembayaran,
        'total': total,
        'dibayar': adalahTunai ? dibayar : total,
        'kembalian': adalahTunai ? dibayar - total : 0,
        'id_pengguna': idPengguna,
        'dibuat_pada': sekarang.millisecondsSinceEpoch,
      });

      String? namaKasirFinal = namaKasir;
      if (namaKasirFinal == null && idPengguna != null) {
        final barisPengguna = await txn.query(
          BasisData.tPengguna,
          columns: ['nama_lengkap'],
          where: 'id = ?',
          whereArgs: [idPengguna],
          limit: 1,
        );
        if (barisPengguna.isNotEmpty) {
          namaKasirFinal = barisPengguna.first['nama_lengkap'] as String?;
        }
      }

      final daftarItem = <ItemPenjualan>[];
      for (final barang in items) {
        final daftarTambahan = barang.daftarTambahan
            .map(
              (m) => TambahanPenjualan(
                idTambahan: m.idTambahan,
                nama: m.nama,
                harga: m.harga,
              ),
            )
            .toList();
        final itemPenjualan = ItemPenjualan(
          idProduk: barang.idProduk,
          nama: barang.nama,
          harga: barang.harga + barang.totalTambahan,
          jumlah: barang.jumlah,
          subtotal: barang.subtotal,
          daftarTambahan: daftarTambahan,
        );
        final idItemPenjualan = await txn.insert(
          BasisData.tItemPenjualan,
          itemPenjualan.kePeta(idTransaksi),
        );
        for (final m in barang.daftarTambahan) {
          await txn.insert(BasisData.tTambahanItemPenjualan, {
            'id_item_penjualan': idItemPenjualan,
            'id_tambahan': m.idTambahan,
            'nama': m.nama,
            'harga': m.harga,
          });
        }
        await txn.rawUpdate(
          'UPDATE ${BasisData.tProduk} SET stok = stok - ? WHERE id = ?',
          [barang.jumlah, barang.idProduk],
        );
        daftarItem.add(
          ItemPenjualan(
            id: idItemPenjualan,
            idProduk: barang.idProduk,
            nama: barang.nama,
            harga: barang.harga + barang.totalTambahan,
            jumlah: barang.jumlah,
            subtotal: barang.subtotal,
            daftarTambahan: daftarTambahan,
          ),
        );
      }

      return TransaksiPenjualan(
        id: idTransaksi,
        nomor: nomor,
        metodePembayaran: metodePembayaran,
        total: total,
        dibayar: adalahTunai ? dibayar : total,
        kembalian: adalahTunai ? dibayar - total : 0,
        dibuatPada: sekarang,
        items: daftarItem,
        idPengguna: idPengguna,
        namaKasir: namaKasirFinal,
      );
    });
  }
}
