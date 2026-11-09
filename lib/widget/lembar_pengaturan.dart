import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../data/basis_data.dart';
import '../penyedia/penyedia_keranjang.dart';
import '../penyedia/penyedia_catatan_kas.dart';
import '../penyedia/penyedia_katalog.dart';
import '../penyedia/penyedia_pengaturan.dart';
import '../penyedia/penyedia_transaksi.dart';
import '../tampilan/tampilan_pengguna.dart';

Future<void> tampilkanLembarPengaturan(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LembarPengaturan(),
  );
}

class LembarPengaturan extends StatefulWidget {
  const LembarPengaturan({super.key});

  @override
  State<LembarPengaturan> createState() => _StatusLembarPengaturan();
}

class _StatusLembarPengaturan extends State<LembarPengaturan> {
  late final TextEditingController _pengendaliNamaToko;
  late final TextEditingController _pengendaliNamaKasir;
  late final TextEditingController _pengendaliHargaMix;
  bool _menyimpan = false;
  bool _mereset = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<PenyediaPengaturan>();
    _pengendaliNamaToko = TextEditingController(text: settings.namaToko);
    _pengendaliNamaKasir = TextEditingController(text: settings.namaKasir);
    _pengendaliHargaMix = TextEditingController(
      text: settings.hargaMixVarian.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _pengendaliNamaToko.dispose();
    _pengendaliNamaKasir.dispose();
    _pengendaliHargaMix.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final hargaMix = int.tryParse(_pengendaliHargaMix.text.trim());
    if (hargaMix == null || hargaMix <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga mix varian harus lebih dari 0.')),
      );
      return;
    }
    setState(() => _menyimpan = true);
    await context.read<PenyediaPengaturan>().save(
      namaToko: _pengendaliNamaToko.text,
      namaKasir: _pengendaliNamaKasir.text,
      hargaMixVarian: hargaMix.toDouble(),
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengaturan toko disimpan.')));
    Navigator.of(context).pop();
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Ulang Semua Data?'),
        content: const Text(
          'Semua transaksi, riwayat keuangan, dan produk akan dihapus, '
          'lalu produk contoh dimasukkan kembali. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WarnaAplikasi.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Atur Ulang'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _mereset = true);
    try {
      await BasisData.instance.resetData();
      if (!mounted) return;
      context.read<PenyediaKeranjang>().clear();
      await Future.wait([
        context.read<PenyediaKatalog>().load(),
        context.read<PenyediaTransaksi>().muatTerbaru(),
        context.read<PenyediaCatatanKas>().load(),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data berhasil diatur ulang.')));
    } catch (galat) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengatur ulang data: $galat')));
    } finally {
      if (mounted) setState(() => _mereset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pengaturan Toko',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: WarnaAplikasi.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pengendaliNamaToko,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Usaha',
                        hintText: 'Pisang Keju Sinar',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pengendaliNamaKasir,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kasir',
                        hintText: 'Sinar',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pengendaliHargaMix,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Harga Mix Varian',
                        hintText: '18000',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.blender_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _menyimpan ? null : _simpan,
                      child: Text(
                        _menyimpan ? 'Menyimpan...' : 'Simpan Pengaturan',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: WarnaAplikasi.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: WarnaAplikasi.primary,
                        ),
                      ),
                      title: const Text(
                        'Kelola Pengguna',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WarnaAplikasi.ink,
                        ),
                      ),
                      subtitle: const Text(
                        'Tambah, ubah, atau nonaktifkan akun kasir.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: WarnaAplikasi.muted,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: WarnaAplikasi.muted,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TampilanPengguna(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: WarnaAplikasi.dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: WarnaAplikasi.danger,
                        ),
                      ),
                      title: const Text(
                        'Atur Ulang Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WarnaAplikasi.ink,
                        ),
                      ),
                      subtitle: const Text(
                        'Hapus semua transaksi, keuangan, dan produk.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: WarnaAplikasi.muted,
                        ),
                      ),
                      trailing: _mereset
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: WarnaAplikasi.muted,
                            ),
                      onTap: _mereset ? null : _resetData,
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Sinar Kasir v1.0.0',
                        style: TextStyle(fontSize: 11, color: WarnaAplikasi.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

