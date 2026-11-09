import 'item_penjualan.dart';

const kPembayaranTunai = 'Tunai';
const kPembayaranQris = 'QRIS';

class TransaksiPenjualan {
  final int? id;
  final String nomor;
  final String metodePembayaran;
  final double total;
  final double dibayar;
  final double kembalian;
  final DateTime dibuatPada;
  final List<ItemPenjualan> items;
  final int? idPengguna;
  final String? namaKasir;

  const TransaksiPenjualan({
    this.id,
    required this.nomor,
    required this.metodePembayaran,
    required this.total,
    required this.dibayar,
    required this.kembalian,
    required this.dibuatPada,
    this.items = const [],
    this.idPengguna,
    this.namaKasir,
  });

  int get jumlahItem => items.length;

  int get totalJumlah => items.fold(0, (sum, barang) => sum + barang.jumlah);

  factory TransaksiPenjualan.dariPeta(
    Map<String, Object?> peta, {
    List<ItemPenjualan> items = const [],
    String? namaKasir,
  }) =>
      TransaksiPenjualan(
        id: peta['id'] as int?,
        nomor: peta['nomor'] as String,
        metodePembayaran: peta['metode_pembayaran'] as String,
        total: (peta['total'] as num).toDouble(),
        dibayar: (peta['dibayar'] as num).toDouble(),
        kembalian: (peta['kembalian'] as num).toDouble(),
        dibuatPada:
            DateTime.fromMillisecondsSinceEpoch(peta['dibuat_pada'] as int),
        items: items,
        idPengguna: (peta['id_pengguna'] as num?)?.toInt(),
        namaKasir: namaKasir,
      );
}
