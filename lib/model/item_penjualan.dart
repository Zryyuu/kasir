class TambahanPenjualan {
  final int? idTambahan;
  final String nama;
  final double harga;

  const TambahanPenjualan({
    this.idTambahan,
    required this.nama,
    required this.harga,
  });

  factory TambahanPenjualan.dariPeta(Map<String, Object?> peta) =>
      TambahanPenjualan(
        idTambahan: (peta['id_tambahan'] as num?)?.toInt(),
        nama: peta['nama'] as String,
        harga: (peta['harga'] as num?)?.toDouble() ?? 0,
      );
}

class ItemPenjualan {
  final int? id;
  final int idProduk;
  final String nama;
  final double harga;
  final int jumlah;
  final double subtotal;
  final List<TambahanPenjualan> daftarTambahan;

  const ItemPenjualan({
    this.id,
    required this.idProduk,
    required this.nama,
    required this.harga,
    required this.jumlah,
    required this.subtotal,
    this.daftarTambahan = const [],
  });

  String get namaTampilan {
    if (daftarTambahan.isEmpty) return nama;
    return '$nama (${daftarTambahan.map((t) => t.nama).join(', ')})';
  }

  Map<String, Object?> kePeta(int idTransaksi) => {
        'id_transaksi': idTransaksi,
        'id_produk': idProduk,
        'nama': nama,
        'harga': harga,
        'jumlah': jumlah,
        'subtotal': subtotal,
      };

  factory ItemPenjualan.dariPeta(
    Map<String, Object?> peta, {
    List<TambahanPenjualan> daftarTambahan = const [],
  }) =>
      ItemPenjualan(
        id: (peta['id'] as num?)?.toInt(),
        idProduk: (peta['id_produk'] as num).toInt(),
        nama: peta['nama'] as String,
        harga: (peta['harga'] as num).toDouble(),
        jumlah: (peta['jumlah'] as num).toInt(),
        subtotal: (peta['subtotal'] as num).toDouble(),
        daftarTambahan: daftarTambahan,
      );
}
