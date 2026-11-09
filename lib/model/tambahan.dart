class Tambahan {
  final int? id;
  final String nama;
  final double harga;
  final bool aktif;

  const Tambahan({
    this.id,
    required this.nama,
    required this.harga,
    this.aktif = true,
  });

  Map<String, Object?> kePeta() => {
        if (id != null) 'id': id,
        'nama': nama,
        'harga': harga,
        'aktif': aktif ? 1 : 0,
        'dibuat_pada': DateTime.now().millisecondsSinceEpoch,
      };

  factory Tambahan.dariPeta(Map<String, Object?> peta) => Tambahan(
        id: peta['id'] as int?,
        nama: peta['nama'] as String,
        harga: (peta['harga'] as num).toDouble(),
        aktif: (peta['aktif'] as num) == 1,
      );
}
