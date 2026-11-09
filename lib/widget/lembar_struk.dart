import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/transaksi_penjualan.dart';
import '../penyedia/penyedia_pengaturan.dart';
import '../layanan/layanan_struk.dart';

Future<void> tampilkanLembarStruk(
  BuildContext context,
  TransaksiPenjualan transaksi, {
  bool celebration = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        LembarStruk(transaksi: transaksi, celebration: celebration),
  );
}

class LembarStruk extends StatefulWidget {
  const LembarStruk({
    super.key,
    required this.transaksi,
    this.celebration = true,
  });

  final TransaksiPenjualan transaksi;
  final bool celebration;

  @override
  State<LembarStruk> createState() => _StatusLembarStruk();
}

class _StatusLembarStruk extends State<LembarStruk> {
  bool _sibuk = false;

  Future<void> _lakukan(
    Future<void> Function(PenyediaPengaturan pengaturan) action,
    String successMessage,
  ) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    final pengaturan = context.read<PenyediaPengaturan>();
    try {
      await action(pengaturan);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (galat) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $galat')));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaksi = widget.transaksi;
    final pengaturan = context.watch<PenyediaPengaturan>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: WarnaAplikasi.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.celebration
                          ? WarnaAplikasi.successSoft
                          : WarnaAplikasi.cream,
                    ),
                    child: Icon(
                      widget.celebration
                          ? Icons.check_rounded
                          : Icons.receipt_long_rounded,
                      color: widget.celebration
                          ? WarnaAplikasi.success
                          : WarnaAplikasi.primaryDark,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.celebration
                        ? 'Transaksi Berhasil'
                        : 'Detail Transaksi',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: WarnaAplikasi.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaksi.nomor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: WarnaAplikasi.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WarnaAplikasi.cream,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: WarnaAplikasi.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          pengaturan.namaToko.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: WarnaAplikasi.ink,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kasir: ${transaksi.namaKasir ?? pengaturan.namaKasir}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: WarnaAplikasi.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GarisPutus(),
                        const SizedBox(height: 10),
                        _BarisInfo('Tanggal', Tanggal.lengkap(transaksi.dibuatPada)),
                        _BarisInfo('Metode', transaksi.metodePembayaran),
                        const SizedBox(height: 8),
                        _GarisPutus(),
                        const SizedBox(height: 8),
                        ...transaksi.items.map(
                          (barang) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  barang.nama,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: WarnaAplikasi.ink,
                                  ),
                                ),
                                if (barang.daftarTambahan.isNotEmpty)
                                  Text(
                                    '+ ${barang.daftarTambahan.map((t) => t.nama).join(', ')}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: WarnaAplikasi.muted,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${barang.jumlah} x ${Uang.format(barang.harga)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: WarnaAplikasi.muted,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      Uang.format(barang.subtotal),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: WarnaAplikasi.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _GarisPutus(),
                        const SizedBox(height: 10),
                        _BarisInfo(
                          'Total',
                          Uang.format(transaksi.total),
                          bold: true,
                        ),
                        _BarisInfo('Bayar', Uang.format(transaksi.dibayar)),
                        if (transaksi.kembalian > 0)
                          _BarisInfo(
                            'Kembali',
                            Uang.format(transaksi.kembalian),
                            color: WarnaAplikasi.success,
                          ),
                        const SizedBox(height: 12),
                        _GarisPutus(),
                        const SizedBox(height: 10),
                        const Text(
                          'Terima kasih sudah berbelanja',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: WarnaAplikasi.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _sibuk
                              ? null
                              : () => _lakukan(
                                  (pengaturan) => LayananStruk.cetakStruk(
                                    transaksi: transaksi,
                                    pengaturan: pengaturan,
                                  ),
                                  'Dialog cetak dibuka.',
                                ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('Cetak'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sibuk
                              ? null
                              : () => _lakukan(
                                  (pengaturan) => LayananStruk.bagikanStruk(
                                    transaksi: transaksi,
                                    pengaturan: pengaturan,
                                  ),
                                  'Struk dibagikan.',
                                ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _sibuk ? null : () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13 : 11.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: WarnaAplikasi.ink,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 14 : 11.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? WarnaAplikasi.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _GarisPutus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor().clamp(1, 100);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: 4,
              height: 1,
              color: WarnaAplikasi.primary.withValues(alpha: 0.35),
            ),
          ),
        );
      },
    );
  }
}


