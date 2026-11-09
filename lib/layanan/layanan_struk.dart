import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../inti/pemformat.dart';
import '../model/transaksi_penjualan.dart';
import '../penyedia/penyedia_pengaturan.dart';

/// Membuat teks struk dan PDF struk ukuran kertas thermal 58 mm.
class LayananStruk {
  static const int _lebar = 32;
  static const String _garis = '--------------------------------';
  static const String _garisGanda = '================================';

  static final PdfPageFormat _formatGulungan = PdfPageFormat(
    58 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 4 * PdfPageFormat.mm,
  );

  static String _duaKolom(String kiri, String kanan) {
    final tersedia = _lebar - kanan.length;
    if (tersedia <= 0) return '$kiri $kanan';
    var teks = kiri;
    if (teks.length > tersedia - 1) {
      teks = '${teks.substring(0, tersedia - 2)}.';
    }
    return teks.padRight(tersedia) + kanan;
  }

  static String _tengah(String teks) {
    if (teks.length >= _lebar) return teks;
    final padding = (_lebar - teks.length) ~/ 2;
    return '${' ' * padding}$teks';
  }

  static String buatTeks({
    required TransaksiPenjualan transaksi,
    required PenyediaPengaturan pengaturan,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_tengah(pengaturan.namaToko.toUpperCase()));
    buffer.writeln(
      _tengah('Kasir: ${transaksi.namaKasir ?? pengaturan.namaKasir}'),
    );
    buffer.writeln(_garisGanda);
    buffer.writeln(_duaKolom('No', transaksi.nomor));
    buffer.writeln(_duaKolom('Tanggal', Tanggal.tanggal(transaksi.dibuatPada)));
    buffer.writeln(_duaKolom('Jam', Tanggal.waktu(transaksi.dibuatPada)));
    buffer.writeln(_duaKolom('Metode', transaksi.metodePembayaran));
    buffer.writeln(_garis);

    for (final barang in transaksi.items) {
      buffer.writeln(barang.nama);
      if (barang.daftarTambahan.isNotEmpty) {
        buffer.writeln(
          '  + ${barang.daftarTambahan.map((t) => t.nama).join(', ')}',
        );
      }
      buffer.writeln(
        _duaKolom(
          '  ${barang.jumlah} x ${Uang.polos(barang.harga)}',
          Uang.polos(barang.subtotal),
        ),
      );
    }

    buffer.writeln(_garis);
    buffer.writeln(_duaKolom('Total', Uang.format(transaksi.total)));
    buffer.writeln(_duaKolom('Bayar', Uang.format(transaksi.dibayar)));
    if (transaksi.kembalian > 0) {
      buffer.writeln(_duaKolom('Kembali', Uang.format(transaksi.kembalian)));
    }
    buffer.writeln(_garisGanda);
    buffer.writeln(_tengah('TERIMA KASIH'));
    buffer.writeln(_tengah('Pisang Keju Sinar'));
    return buffer.toString();
  }

  static Future<Uint8List> buatPdf({
    required TransaksiPenjualan transaksi,
    required PenyediaPengaturan pengaturan,
  }) async {
    final dokumen = pw.Document();

    dokumen.addPage(
      pw.Page(
        pageFormat: _formatGulungan,
        build: (context) {
          final kecil = pw.TextStyle(fontSize: 8, color: PdfColors.black);
          final tebal = pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );

          pw.Widget baris(String kiri, String kanan, {bool tebalTeks = false}) {
            final gaya = tebalTeks ? tebal : kecil;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(kiri, style: gaya)),
                  pw.SizedBox(width: 4),
                  pw.Text(kanan, style: gaya),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  pengaturan.namaToko.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Kasir: ${transaksi.namaKasir ?? pengaturan.namaKasir}',
                  style: kecil,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, height: 8),
              baris('No', transaksi.nomor),
              baris('Tanggal', Tanggal.tanggal(transaksi.dibuatPada)),
              baris('Jam', Tanggal.waktu(transaksi.dibuatPada)),
              baris('Metode', transaksi.metodePembayaran),
              pw.Divider(thickness: 0.5, height: 8),
              ...transaksi.items.map(
                (barang) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(barang.nama, style: kecil),
                    if (barang.daftarTambahan.isNotEmpty)
                      pw.Text(
                        '  + ${barang.daftarTambahan.map((t) => t.nama).join(', ')}',
                        style: kecil,
                      ),
                    baris(
                      '${barang.jumlah} x ${Uang.format(barang.harga)}',
                      Uang.format(barang.subtotal),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5, height: 8),
              baris('Total', Uang.format(transaksi.total), tebalTeks: true),
              baris('Bayar', Uang.format(transaksi.dibayar)),
              if (transaksi.kembalian > 0)
                baris('Kembali', Uang.format(transaksi.kembalian)),
              pw.Divider(thickness: 0.5, height: 8),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'TERIMA KASIH',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(child: pw.Text('Pisang Keju Sinar', style: kecil)),
            ],
          );
        },
      ),
    );

    return dokumen.save();
  }

  /// Membuka dialog cetak bawaan perangkat.
  static Future<bool> cetakStruk({
    required TransaksiPenjualan transaksi,
    required PenyediaPengaturan pengaturan,
  }) async {
    final bytes = await buatPdf(transaksi: transaksi, pengaturan: pengaturan);
    return Printing.layoutPdf(
      name: 'Struk ${transaksi.nomor}',
      onLayout: (format) async => bytes,
    );
  }

  /// Membagikan struk sebagai PDF.
  static Future<bool> bagikanStruk({
    required TransaksiPenjualan transaksi,
    required PenyediaPengaturan pengaturan,
  }) async {
    final bytes = await buatPdf(transaksi: transaksi, pengaturan: pengaturan);
    return Printing.sharePdf(
      bytes: bytes,
      filename: 'struk-${transaksi.nomor}.pdf',
      subject: 'Struk ${transaksi.nomor}',
      body: 'Struk pembelian ${pengaturan.namaToko}',
    );
  }
}
