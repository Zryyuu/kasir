class TambahanItemKeranjang {
  final int? idTambahan;
  final String nama;
  final double harga;

  const TambahanItemKeranjang({
    this.idTambahan,
    required this.nama,
    required this.harga,
  });

  Map<String, Object?> kePeta() => {
        'id_tambahan': idTambahan,
        'nama': nama,
        'harga': harga,
      };
}

class ItemKeranjang {
  final int idProduk;
  final String nama;
  final double harga;
  final int jumlah;

  /// Stok produk saat item dimasukkan ke keranjang.
  final int stok;
  final List<TambahanItemKeranjang> daftarTambahan;

  const ItemKeranjang({
    required this.idProduk,
    required this.nama,
    required this.harga,
    required this.jumlah,
    required this.stok,
    this.daftarTambahan = const [],
  });

  double get totalTambahan =>
      daftarTambahan.fold(0, (sum, m) => sum + m.harga);

  double get subtotal => (harga + totalTambahan) * jumlah;

  String get namaTampilan {
    if (daftarTambahan.isEmpty) return nama;
    final namaTambahan = daftarTambahan.map((m) => m.nama).join(', ');
    return '$nama ($namaTambahan)';
  }

  ItemKeranjang salinDengan({
    int? jumlah,
    int? stok,
    List<TambahanItemKeranjang>? daftarTambahan,
  }) =>
      ItemKeranjang(
        idProduk: idProduk,
        nama: nama,
        harga: harga,
        jumlah: jumlah ?? this.jumlah,
        stok: stok ?? this.stok,
        daftarTambahan: daftarTambahan ?? this.daftarTambahan,
      );
}
