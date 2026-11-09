import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/catatan_kas.dart';
import '../penyedia/penyedia_catatan_kas.dart';
import '../penyedia/pengendali_shell.dart';
import '../widget/lembar_catatan_kas.dart';
import '../widget/keadaan_kosong.dart';

class TampilanKeuangan extends StatefulWidget {
  const TampilanKeuangan({super.key});

  @override
  State<TampilanKeuangan> createState() => _StatusTampilanKeuangan();
}

class _StatusTampilanKeuangan extends State<TampilanKeuangan> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _gantiBulan(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _openEntrySheet({
    CatatanKas? catatan,
    required JenisCatatanKas jenis,
  }) {
    return tampilkanLembarCatatanKas(context, catatan: catatan, jenis: jenis);
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<PengendaliShell>();
    final kas = context.watch<PenyediaCatatanKas>();
    final jenis = shell.tabKeuangan == 0
        ? JenisCatatanKas.pengeluaran
        : JenisCatatanKas.pemasukan;
    final daftarCatatan = kas
        .catatanUntukBulan(_month)
        .where((catatan) => catatan.jenis == jenis)
        .toList();
    final adalahPengeluaran = jenis == JenisCatatanKas.pengeluaran;
    final totalPemasukan = kas.totalUntukBulan(JenisCatatanKas.pemasukan, _month);
    final totalPengeluaran = kas.totalUntukBulan(JenisCatatanKas.pengeluaran, _month);
    final total = adalahPengeluaran ? totalPengeluaran : totalPemasukan;
    final laba = totalPemasukan - totalPengeluaran;
    final color = adalahPengeluaran ? WarnaAplikasi.danger : WarnaAplikasi.success;
    final softColor = adalahPengeluaran ? WarnaAplikasi.dangerSoft : WarnaAplikasi.successSoft;
    final now = DateTime.now();
    final bisaLanjut =
        _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan'),
        actions: [
          IconButton(
            tooltip: 'Tambah catatan',
            onPressed: () => _openEntrySheet(jenis: jenis),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _TombolTabKeuangan(
                    label: 'Pengeluaran',
                    icon: Icons.trending_down_rounded,
                    selected: jenis == JenisCatatanKas.pengeluaran,
                    color: WarnaAplikasi.danger,
                    onTap: () => shell.aturTabKeuangan(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TombolTabKeuangan(
                    label: 'Kas Masuk',
                    icon: Icons.trending_up_rounded,
                    selected: jenis == JenisCatatanKas.pemasukan,
                    color: WarnaAplikasi.success,
                    onTap: () => shell.aturTabKeuangan(1),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _gantiBulan(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: WarnaAplikasi.border),
                  ),
                ),
                Expanded(
                  child: Text(
                    Tanggal.bulanTahun(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: WarnaAplikasi.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: bisaLanjut ? () => _gantiBulan(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: WarnaAplikasi.border),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      adalahPengeluaran
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
          adalahPengeluaran
              ? 'Total Pengeluaran Bulan Ini'
              : 'Total Kas Masuk Bulan Ini',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: WarnaAplikasi.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Uang.format(total),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${daftarCatatan.length} catatan',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: WarnaAplikasi.muted,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                'Laba ${Uang.format(laba)}',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: laba >= 0
                                      ? WarnaAplikasi.ink
                                      : WarnaAplikasi.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: daftarCatatan.isEmpty
                ? KeadaanKosong(
                    icon: adalahPengeluaran
                        ? Icons.receipt_long_outlined
                        : Icons.savings_outlined,
                    title: adalahPengeluaran
                    ? 'Belum ada pengeluaran'
                    : 'Belum ada kas masuk',
                message: adalahPengeluaran
                    ? 'Catat belanja bahan, gas, transportasi, dan biaya lain di sini.'
                    : 'Catat modal, pemasukan lain, atau kas masuk lainnya di sini.',
                actionLabel: adalahPengeluaran
                    ? 'Tambah Pengeluaran'
                    : 'Tambah Kas Masuk',
                onAction: () => _openEntrySheet(jenis: jenis),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 100),
                    itemCount: daftarCatatan.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final catatan = daftarCatatan[index];
                      return _UbinCatatanKas(
                        catatan: catatan,
                        onTap: () =>
                            _openEntrySheet(catatan: catatan, jenis: catatan.jenis),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntrySheet(jenis: jenis),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(adalahPengeluaran ? 'Pengeluaran' : 'Kas Masuk'),
      ),
    );
  }
}

class _TombolTabKeuangan extends StatelessWidget {
  const _TombolTabKeuangan({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : WarnaAplikasi.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? color : WarnaAplikasi.muted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : WarnaAplikasi.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UbinCatatanKas extends StatelessWidget {
  const _UbinCatatanKas({required this.catatan, required this.onTap});

  final CatatanKas catatan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adalahPengeluaran = catatan.jenis == JenisCatatanKas.pengeluaran;
    final color = adalahPengeluaran ? WarnaAplikasi.danger : WarnaAplikasi.success;
    final softColor = adalahPengeluaran ? WarnaAplikasi.dangerSoft : WarnaAplikasi.successSoft;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(catatan.kategori),
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catatan.kategori,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WarnaAplikasi.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      catatan.keterangan == null || catatan.keterangan!.isEmpty
                          ? Tanggal.tanggal(catatan.dibuatPada)
                          : '${catatan.keterangan} · ${Tanggal.tanggal(catatan.dibuatPada)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: WarnaAplikasi.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${adalahPengeluaran ? '-' : '+'}${Uang.format(catatan.jumlah)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String kategori) {
  switch (kategori) {
    case 'Modal':
      return Icons.account_balance_wallet_outlined;
    case 'Beli Bahan':
      return Icons.shopping_basket_outlined;
    case 'Gas & Listrik':
      return Icons.bolt_rounded;
    case 'Transportasi':
      return Icons.directions_bike_outlined;
    case 'Gaji':
      return Icons.groups_outlined;
    case 'Sewa':
      return Icons.storefront_outlined;
    case 'Peralatan':
      return Icons.build_outlined;
    case 'Penjualan Lain':
      return Icons.sell_outlined;
    case 'Jual Sisa':
      return Icons.recycling_rounded;
    case 'Titipan':
      return Icons.inventory_2_outlined;
    default:
      return Icons.more_horiz_rounded;
  }
}
