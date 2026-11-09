class Produk {
  final int? id;
  final String nama;
  final double harga;
  final int stok;
  final bool aktif;
  final DateTime dibuatPada;

  const Produk({
    this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    this.aktif = true,
    required this.dibuatPada,
  });

  bool get stokHabis => stok <= 0;

  bool get stokRendah => stok > 0 && stok <= 5;

  Map<String, Object?> kePeta() => {
        if (id != null) 'id': id,
        'nama': nama,
        'harga': harga,
        'stok': stok,
        'aktif': aktif ? 1 : 0,
        'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
      };

  factory Produk.dariPeta(Map<String, Object?> peta) => Produk(
        id: peta['id'] as int?,
        nama: peta['nama'] as String,
        harga: (peta['harga'] as num).toDouble(),
        stok: (peta['stok'] as num).toInt(),
        aktif: (peta['aktif'] as num? ?? 1) == 1,
        dibuatPada:
            DateTime.fromMillisecondsSinceEpoch(peta['dibuat_pada'] as int),
      );

  Produk salinDengan({
    String? nama,
    double? harga,
    int? stok,
    bool? aktif,
  }) =>
      Produk(
        id: id,
        nama: nama ?? this.nama,
        harga: harga ?? this.harga,
        stok: stok ?? this.stok,
        aktif: aktif ?? this.aktif,
        dibuatPada: dibuatPada,
      );
}
