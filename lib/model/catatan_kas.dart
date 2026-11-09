enum JenisCatatanKas {
  pemasukan('pemasukan', 'Pemasukan'),
  pengeluaran('pengeluaran', 'Pengeluaran');

  const JenisCatatanKas(this.nilai, this.label);
  final String nilai;
  final String label;

  static JenisCatatanKas dariNilai(String nilai) => JenisCatatanKas.values
      .firstWhere((jenis) => jenis.nilai == nilai, orElse: () => JenisCatatanKas.pengeluaran);
}

class CatatanKas {
  final int? id;
  final JenisCatatanKas jenis;
  final String kategori;
  final double jumlah;
  final String? keterangan;
  final DateTime dibuatPada;

  const CatatanKas({
    this.id,
    required this.jenis,
    required this.kategori,
    required this.jumlah,
    this.keterangan,
    required this.dibuatPada,
  });

  Map<String, Object?> kePeta() => {
        if (id != null) 'id': id,
        'jenis': jenis.nilai,
        'kategori': kategori,
        'jumlah': jumlah,
        'keterangan': keterangan,
        'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
      };

  factory CatatanKas.dariPeta(Map<String, Object?> peta) => CatatanKas(
        id: peta['id'] as int?,
        jenis: JenisCatatanKas.dariNilai(peta['jenis'] as String),
        kategori: peta['kategori'] as String,
        jumlah: (peta['jumlah'] as num).toDouble(),
        keterangan: peta['keterangan'] as String?,
        dibuatPada:
            DateTime.fromMillisecondsSinceEpoch(peta['dibuat_pada'] as int),
      );

  CatatanKas salinDengan({
    JenisCatatanKas? jenis,
    String? kategori,
    double? jumlah,
    String? keterangan,
    bool hapusKeterangan = false,
    DateTime? dibuatPada,
  }) =>
      CatatanKas(
        id: id,
        jenis: jenis ?? this.jenis,
        kategori: kategori ?? this.kategori,
        jumlah: jumlah ?? this.jumlah,
        keterangan: hapusKeterangan ? null : (keterangan ?? this.keterangan),
        dibuatPada: dibuatPada ?? this.dibuatPada,
      );
}

const kKategoriPengeluaran = [
  'Beli Bahan',
  'Gas & Listrik',
  'Transportasi',
  'Gaji',
  'Sewa',
  'Peralatan',
  'Kerugian Stok',
  'Lainnya',
];

const kSumberPemasukan = [
  'Modal',
  'Penjualan Lain',
  'Jual Sisa',
  'Titipan',
  'Lainnya',
];
