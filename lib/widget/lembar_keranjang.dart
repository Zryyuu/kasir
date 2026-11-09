import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../data/basis_data.dart';
import '../model/transaksi_penjualan.dart';
import '../penyedia/penyedia_auth.dart';
import '../penyedia/penyedia_keranjang.dart';
import '../penyedia/penyedia_katalog.dart';
import '../layanan/layanan_penjualan.dart';

/// Keranjang & checkout untuk halaman Kasir.
class LembarKeranjang extends StatefulWidget {
  const LembarKeranjang({
    super.key,
    required this.keranjang,
    required this.catalog,
    required this.db,
  });

  final PenyediaKeranjang keranjang;
  final PenyediaKatalog catalog;
  final BasisData db;

  static Future<TransaksiPenjualan?> show(
    BuildContext context, {
    required PenyediaKeranjang keranjang,
    required PenyediaKatalog catalog,
    required BasisData db,
  }) {
    return showModalBottomSheet<TransaksiPenjualan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LembarKeranjang(keranjang: keranjang, catalog: catalog, db: db),
    );
  }

  @override
  State<LembarKeranjang> createState() => _StatusLembarKeranjang();
}

class _StatusLembarKeranjang extends State<LembarKeranjang> {
  String _metodePembayaran = kPembayaranTunai;
  bool _menyimpan = false;

  PenyediaKeranjang get _keranjang => widget.keranjang;

  bool get _bisaBayar => !_keranjang.isEmpty;

  Future<void> _simpanTransaksi() async {
    if (!_bisaBayar || _menyimpan) return;
    setState(() => _menyimpan = true);
    try {
      final pengguna = Provider.of<PenyediaAuth>(
        context,
        listen: false,
      ).penggunaSaatIni;
      final service = LayananPenjualan(widget.db);
      final transaksi = await service.checkout(
        items: _keranjang.items,
        metodePembayaran: _metodePembayaran,
        dibayar: _keranjang.total,
        idPengguna: pengguna?.id,
        namaKasir: pengguna?.namaLengkap,
      );
      _keranjang.clear();
      await widget.catalog.load();
      if (!mounted) return;
      Navigator.of(context).pop(transaksi);
    } on PengecualianPenjualan catch (galat) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(galat.pesan)));
    } catch (galat) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $galat')),
      );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _keranjang,
      builder: (context, child) => _buatKonten(context),
    );
  }

  Widget _buatKonten(BuildContext context) {
    final total = _keranjang.total;

    return Padding(
      padding: EdgeInsets.zero,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      const Text(
                        'Keranjang & Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: WarnaAplikasi.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: WarnaAplikasi.muted,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    children: [
                      ..._keranjang.items.asMap().entries.map((catatan) {
                        final index = catatan.key;
                        final barang = catatan.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: WarnaAplikasi.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: WarnaAplikasi.cream,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                  color: WarnaAplikasi.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      barang.nama,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: WarnaAplikasi.ink,
                                      ),
                                    ),
                                    if (barang.daftarTambahan.isNotEmpty)
                                      Text(
                                        barang.daftarTambahan
                                            .map((m) => m.nama)
                                            .join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: WarnaAplikasi.muted,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${Uang.format(barang.harga + barang.totalTambahan)} / porsi',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: WarnaAplikasi.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TombolBulat(
                                    icon: Icons.remove_rounded,
                                    onTap: () => _keranjang.kurangiJumlah(index),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      '${barang.jumlah}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: WarnaAplikasi.ink,
                                      ),
                                    ),
                                  ),
                                  _TombolBulat(
                                    icon: Icons.add_rounded,
                                    onTap: () => _keranjang.tambahJumlah(index),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                Uang.format(barang.subtotal),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: WarnaAplikasi.ink,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: WarnaAplikasi.cream,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: WarnaAplikasi.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Total Belanja',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: WarnaAplikasi.ink,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  Uang.format(total),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: WarnaAplikasi.primaryDark,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: WarnaAplikasi.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _ChipMetode(
                                  label: kPembayaranTunai,
                                  selected: _metodePembayaran == kPembayaranTunai,
                                  onTap: () => setState(
                                    () => _metodePembayaran = kPembayaranTunai,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ChipMetode(
                                  label: kPembayaranQris,
                                  selected: _metodePembayaran == kPembayaranQris,
                                  onTap: () => setState(
                                    () => _metodePembayaran = kPembayaranQris,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: WarnaAplikasi.infoSoft,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: WarnaAplikasi.info.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _metodePembayaran == kPembayaranTunai
                                        ? Icons.payments_rounded
                                        : Icons.qr_code_rounded,
                                    size: 18,
                                    color: WarnaAplikasi.info,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _metodePembayaran == kPembayaranTunai
                                          ? 'Pembayaran tunai dicatat uang pas. Tidak perlu input nominal.'
                                          : 'Pembayaran QRIS otomatis uang pas.',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: WarnaAplikasi.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: FilledButton(
                      onPressed: _bisaBayar && !_menyimpan ? _simpanTransaksi : null,
                      child: Text(
                        _menyimpan ? 'Menyimpan...' : 'SIMPAN TRANSAKSI',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TombolBulat extends StatelessWidget {
  const _TombolBulat({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: WarnaAplikasi.border),
        ),
        child: Icon(icon, size: 18, color: WarnaAplikasi.ink),
      ),
    );
  }
}

class _ChipMetode extends StatelessWidget {
  const _ChipMetode({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? WarnaAplikasi.primary.withValues(alpha: 0.16)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? WarnaAplikasi.primary : WarnaAplikasi.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.ink,
            ),
          ),
        ),
      ),
    );
  }
}




