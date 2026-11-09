import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/catatan_kas.dart';
import '../model/transaksi_penjualan.dart';
import '../penyedia/penyedia_auth.dart';
import '../penyedia/penyedia_catatan_kas.dart';
import '../penyedia/penyedia_keranjang.dart';
import '../penyedia/penyedia_katalog.dart';
import '../penyedia/penyedia_pengaturan.dart';
import '../penyedia/pengendali_shell.dart';
import '../penyedia/penyedia_transaksi.dart';
import '../widget/keadaan_kosong.dart';
import '../widget/tombol_aksi_cepat.dart';
import '../widget/lembar_struk.dart';
import '../widget/judul_bagian.dart';
import '../widget/lembar_pengaturan.dart';
import 'tampilan_produk.dart';

class TampilanBeranda extends StatelessWidget {
  const TampilanBeranda({super.key});

  Future<void> _segarkan(BuildContext context) async {
    await Future.wait([
      context.read<PenyediaKatalog>().load(),
      context.read<PenyediaTransaksi>().muatTerbaru(),
      context.read<PenyediaCatatanKas>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<PenyediaPengaturan>();
    final daftarTransaksi = context.watch<PenyediaTransaksi>();
    final kas = context.watch<PenyediaCatatanKas>();
    final auth = context.watch<PenyediaAuth>();
    final adalahAdmin = auth.adalahAdmin;
    final shell = context.read<PengendaliShell>();

    final penjualan = daftarTransaksi.ringkasanHariIni.penjualan;
    final manualIncome = kas.totalHariIni(JenisCatatanKas.pemasukan);
    final pengeluaran = kas.totalHariIni(JenisCatatanKas.pengeluaran);
    final net = penjualan + manualIncome - pengeluaran;
    final terbaru = daftarTransaksi.terbaru.take(5).toList();

    return SafeArea(
      child: RefreshIndicator(
        color: WarnaAplikasi.primary,
        onRefresh: () => _segarkan(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [WarnaAplikasi.primaryLight, Color(0xFFBFDBFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: WarnaAplikasi.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'S',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: WarnaAplikasi.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.namaToko,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: WarnaAplikasi.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kasir: ${auth.penggunaSaatIni?.namaLengkap ?? '-'} (${adalahAdmin ? 'Admin' : 'Kasir'})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: WarnaAplikasi.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Keluar',
                    onPressed: () {
                      context.read<PenyediaKeranjang>().clear();
                      shell.reset();
                      context.read<PenyediaAuth>().keluar();
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: WarnaAplikasi.ink,
                    ),
                  ),
                  if (adalahAdmin)
                    IconButton(
                      tooltip: 'Pengaturan',
                      onPressed: () => tampilkanLembarPengaturan(context),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: WarnaAplikasi.ink,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _KartuHariIni(
                net: net,
                penjualan: penjualan,
                manualIncome: manualIncome,
                pengeluaran: pengeluaran,
                jumlahTransaksi: daftarTransaksi.ringkasanHariIni.jumlahTransaksi,
                jumlah: daftarTransaksi.ringkasanHariIni.jumlah,
              ),
            ),
            const SizedBox(height: 22),
            if (adalahAdmin)
              const JudulBagian(title: 'Aksi Cepat'),
            if (adalahAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.12,
                  children: [
                    TombolAksiCepat(
                      icon: Icons.point_of_sale_rounded,
                      label: 'Kasir',
                      color: WarnaAplikasi.primary,
                      onTap: () => shell.go(1),
                    ),
                    TombolAksiCepat(
                      icon: Icons.inventory_2_rounded,
                      label: 'Produk',
                      color: const Color(0xFF6366F1),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TampilanProduk()),
                      ),
                    ),
                    TombolAksiCepat(
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat',
                      color: WarnaAplikasi.info,
                      onTap: () => shell.go(2),
                    ),
                    TombolAksiCepat(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Keuangan',
                      color: WarnaAplikasi.primary,
                      onTap: () => shell.go(4),
                    ),
                    TombolAksiCepat(
                      icon: Icons.bar_chart_rounded,
                      label: 'Laporan',
                      color: WarnaAplikasi.accent,
                      onTap: () => shell.go(3),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TombolAksiCepat(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Buka Kasir',
                  color: WarnaAplikasi.primary,
                  onTap: () => shell.go(1),
                ),
              ),
            const SizedBox(height: 24),
            JudulBagian(
              title: 'Transaksi Terakhir',
              actionLabel: adalahAdmin ? 'Lihat semua' : null,
              onAction: adalahAdmin ? () => shell.go(2) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: terbaru.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: WarnaAplikasi.border),
                      ),
                      child: const KeadaanKosong(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada transaksi',
                        message: 'Transaksi yang kamu simpan di Kasir akan muncul di sini.',
                        compact: true,
                      ),
                    )
                  : Column(
                      children: terbaru
                          .map(
                            (transaksi) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UbinTransaksi(transaksi: transaksi),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuHariIni extends StatelessWidget {
  const _KartuHariIni({
    required this.net,
    required this.penjualan,
    required this.manualIncome,
    required this.pengeluaran,
    required this.jumlahTransaksi,
    required this.jumlah,
  });

  final double net;
  final double penjualan;
  final double manualIncome;
  final double pengeluaran;
  final int jumlahTransaksi;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E40AF)),
        boxShadow: [
          BoxShadow(
            color: WarnaAplikasi.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'LABA BERSIH HARI INI',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDBEAFE),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  Tanggal.tanggal(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Uang.format(net),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatistikMini(label: 'Penjualan', value: Uang.format(penjualan)),
              const SizedBox(width: 8),
              _StatistikMini(label: 'Pemasukan', value: Uang.format(manualIncome)),
              const SizedBox(width: 8),
              _StatistikMini(label: 'Pengeluaran', value: Uang.format(pengeluaran)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '$jumlahTransaksi transaksi Â· $jumlah porsi terjual',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDBEAFE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatistikMini extends StatelessWidget {
  const _StatistikMini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDBEAFE),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UbinTransaksi extends StatelessWidget {
  const _UbinTransaksi({required this.transaksi});
  final TransaksiPenjualan transaksi;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => tampilkanLembarStruk(context, transaksi, celebration: false),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WarnaAplikasi.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
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
                      transaksi.nomor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: WarnaAplikasi.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Tanggal.waktu(transaksi.dibuatPada)} Â· '
                      '${transaksi.metodePembayaran} Â· '
                      '${transaksi.totalJumlah} porsi',
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
                Uang.format(transaksi.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: WarnaAplikasi.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

