import '../data/basis_data.dart';
import '../model/produk.dart';

const kAlasanTambahStok = ['Restok', 'Koreksi stok', 'Lainnya'];
const kAlasanKurangStok = [
  'Koreksi stok',
  'Rusak',
  'Terbuang',
  'Hilang',
  'Lainnya',
];
const kAlasanKerugianStok = {'Rusak', 'Terbuang', 'Hilang'};

class HasilPenyesuaianStok {
  const HasilPenyesuaianStok({
    required this.jumlah,
    required this.alasan,
    required this.stokBaru,
    required this.jumlahKerugian,
  });

  final int jumlah;
  final String alasan;
  final int stokBaru;
  final double jumlahKerugian;

  bool get adalahKerugian => jumlahKerugian > 0;
}

/// Mengubah stok manual dengan alasan dan mencatat kerugian stok.
class LayananStok {
  LayananStok(this._basisData);

  final BasisData _basisData;

  Future<HasilPenyesuaianStok> sesuaikanStok({
    required Produk produk,
    required int delta,
    required String alasan,
    String? keterangan,
  }) async {
    if (delta == 0) {
      throw StateError('Jumlah perubahan stok tidak boleh 0.');
    }
    if (!kAlasanTambahStok.contains(alasan) &&
        !kAlasanKurangStok.contains(alasan)) {
      throw StateError('Alasan perubahan stok tidak dikenal.');
    }

    final idProduk = produk.id;
    if (idProduk == null) {
      throw StateError('Produk belum tersimpan.');
    }

    final jumlah = delta.abs();
    final adalahKerugian = delta < 0 && kAlasanKerugianStok.contains(alasan);
    final jumlahKerugian = adalahKerugian ? jumlah * produk.harga : 0.0;
    final catatanBersih = (keterangan ?? '').trim();
    final sekarang = DateTime.now();
    final db = await _basisData.database;

    final stokBaru = await db.transaction((txn) async {
      final baris = await txn.query(
        BasisData.tProduk,
        columns: ['stok'],
        where: 'id = ?',
        whereArgs: [idProduk],
        limit: 1,
      );
      if (baris.isEmpty) {
        throw StateError('Produk tidak ditemukan.');
      }
      final stokSekarang = (baris.first['stok'] as num).toInt();
      final berikutnya = stokSekarang + delta;
      if (berikutnya < 0) {
        throw StateError('Stok tidak boleh kurang dari 0.');
      }

      await txn.update(
        BasisData.tProduk,
        {'stok': berikutnya},
        where: 'id = ?',
        whereArgs: [idProduk],
      );
      await txn.insert(BasisData.tPenyesuaianStok, {
        'id_produk': idProduk,
        'nama_produk': produk.nama,
        'perubahan_jumlah': delta,
        'alasan': alasan,
        'catatan': catatanBersih.isEmpty ? null : catatanBersih,
        'nilai_kerugian': jumlahKerugian,
        'dibuat_pada': sekarang.millisecondsSinceEpoch,
      });

      if (adalahKerugian && jumlahKerugian > 0) {
        final bagianCatatan = [
          alasan,
          '${produk.nama} $jumlah porsi',
          if (catatanBersih.isNotEmpty) catatanBersih,
        ];
        await txn.insert(BasisData.tCatatanKas, {
          'jenis': 'pengeluaran',
          'kategori': 'Kerugian Stok',
          'jumlah': jumlahKerugian,
          'keterangan': bagianCatatan.join(' · '),
          'dibuat_pada': sekarang.millisecondsSinceEpoch,
        });
      }

      return berikutnya;
    });

    return HasilPenyesuaianStok(
      jumlah: jumlah,
      alasan: alasan,
      stokBaru: stokBaru,
      jumlahKerugian: jumlahKerugian,
    );
  }
}
