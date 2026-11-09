import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/catatan_kas.dart';
import '../model/transaksi_penjualan.dart';
import '../penyedia/penyedia_catatan_kas.dart';
import '../penyedia/penyedia_transaksi.dart';
import '../widget/lembar_struk.dart';
import '../widget/kartu_statistik.dart';
import 'tampilan_riwayat.dart';

enum _PeriodeLaporan { today, week, month, custom }

class TampilanLaporan extends StatefulWidget {
  const TampilanLaporan({super.key});

  @override
  State<TampilanLaporan> createState() => _StatusTampilanLaporan();
}

class _StatusTampilanLaporan extends State<TampilanLaporan> {
  _PeriodeLaporan _periode = _PeriodeLaporan.month;
  DateTimeRange? _rentangKhusus;
  _DataLaporan? _data;
  bool _memuat = true;
  int _idPermintaan = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _muat();
    });
  }

  DateTimeRange _rentang() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_periode) {
      case _PeriodeLaporan.today:
        return DateTimeRange(start: today, end: now);
      case _PeriodeLaporan.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: now,
        );
      case _PeriodeLaporan.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _PeriodeLaporan.custom:
        return _rentangKhusus ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  Future<void> _pilihRentangKhusus() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange:
          _rentangKhusus ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      helpText: 'Pilih rentang laporan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _rentangKhusus = picked;
      _periode = _PeriodeLaporan.custom;
    });
    _muat();
  }

  void _pilihPeriode(_PeriodeLaporan periode) {
    if (periode == _PeriodeLaporan.custom) {
      _pilihRentangKhusus();
      return;
    }
    setState(() => _periode = periode);
    _muat();
  }

  Future<void> _muat() async {
    final idPermintaan = ++_idPermintaan;
    if (mounted) setState(() => _memuat = true);
    final rentang = _rentang();
    final transactionsProvider = context.read<PenyediaTransaksi>();
    final cashProvider = context.read<PenyediaCatatanKas>();

    try {
      final daftarTransaksi = await transactionsProvider.berdasarkanRentang(
        rentang.start,
        rentang.end,
      );
      final produkTerlaris = await transactionsProvider.produkTerlaris(
        rentang.start,
        rentang.end,
      );
      final daftarCatatanKas = cashProvider.catatanAntara(rentang.start, rentang.end);

      if (!mounted || idPermintaan != _idPermintaan) return;
      setState(() {
        _data = _DataLaporan.from(
          rentang: rentang,
          daftarTransaksi: daftarTransaksi,
          daftarCatatanKas: daftarCatatanKas,
          produkTerlaris: produkTerlaris,
        );
        _memuat = false;
      });
    } catch (galat) {
      if (!mounted || idPermintaan != _idPermintaan) return;
      setState(() => _memuat = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat laporan: $galat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final rentang = _rentang();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _muat,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _ChipFilter(
                  label: 'Hari Ini',
                  selected: _periode == _PeriodeLaporan.today,
                  onTap: () => _pilihPeriode(_PeriodeLaporan.today),
                ),
                const SizedBox(width: 7),
                _ChipFilter(
                  label: '7 Hari',
                  selected: _periode == _PeriodeLaporan.week,
                  onTap: () => _pilihPeriode(_PeriodeLaporan.week),
                ),
                const SizedBox(width: 7),
                _ChipFilter(
                  label: 'Bulan Ini',
                  selected: _periode == _PeriodeLaporan.month,
                  onTap: () => _pilihPeriode(_PeriodeLaporan.month),
                ),
                const SizedBox(width: 7),
                _ChipFilter(
                  label: _periode == _PeriodeLaporan.custom && _rentangKhusus != null
                      ? '${Tanggal.tanggal(_rentangKhusus!.start)} - ${Tanggal.tanggal(_rentangKhusus!.end)}'
                      : 'Pilih Tanggal',
                  selected: _periode == _PeriodeLaporan.custom,
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _pilihPeriode(_PeriodeLaporan.custom),
                ),
              ],
            ),
          ),
          if (_periode == _PeriodeLaporan.custom)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${Tanggal.tanggal(rentang.start)} - ${Tanggal.tanggal(rentang.end)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: WarnaAplikasi.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_memuat) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: data == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: WarnaAplikasi.primary,
                    onRefresh: _muat,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.15,
                          children: [
                            KartuStatistik(
                              label: 'Penjualan',
                              value: Uang.format(data.penjualan),
                              icon: Icons.point_of_sale_rounded,
                              color: WarnaAplikasi.primaryDark,
                              softColor: WarnaAplikasi.cream,
                            ),
                            KartuStatistik(
                              label: 'Pemasukan',
                              value: Uang.format(data.pemasukan),
                              icon: Icons.trending_up_rounded,
                              color: WarnaAplikasi.success,
                              softColor: WarnaAplikasi.successSoft,
                            ),
                            KartuStatistik(
                              label: 'Pengeluaran',
                              value: Uang.format(data.pengeluaran),
                              icon: Icons.trending_down_rounded,
                              color: WarnaAplikasi.danger,
                              softColor: WarnaAplikasi.dangerSoft,
                            ),
                            KartuStatistik(
                              label: 'Laba Bersih',
                              value: Uang.format(data.net),
                              icon: Icons.account_balance_wallet_rounded,
                              color: data.net >= 0
                                  ? WarnaAplikasi.success
                                  : WarnaAplikasi.danger,
                              softColor: data.net >= 0
                                  ? WarnaAplikasi.successSoft
                                  : WarnaAplikasi.dangerSoft,
                              subtitle: 'Penjualan + pemasukan - pengeluaran',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: WarnaAplikasi.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 15,
                                color: WarnaAplikasi.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${data.jumlahTransaksi} transaksi · '
                                  '${data.jumlah} porsi terjual',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: WarnaAplikasi.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'Rata-rata ${Uang.format(data.average)}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: WarnaAplikasi.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _KartuGrafik(days: data.daily),
                        const SizedBox(height: 16),
                        _KartuProdukTerlaris(daftarProduk: data.produkTerlaris),
                        const SizedBox(height: 16),
                        _KartuRincianPengeluaran(daftarCatatan: data.expenseByCategory),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Transaksi Terakhir',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: WarnaAplikasi.ink,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TampilanRiwayat(),
                                ),
                              ),
                              child: const Text('Lihat semua'),
                            ),
                          ],
                        ),
                        if (data.daftarTransaksi.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'Belum ada transaksi pada periode ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WarnaAplikasi.muted,
                                ),
                              ),
                            ),
                          )
                        else
                          ...data.daftarTransaksi
                              .take(5)
                              .map(
                                (transaksi) => Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: _UbinTransaksiTerakhir(
                                    transaksi: transaksi,
                                    onTap: () => tampilkanLembarStruk(
                                      context,
                                      transaksi,
                                      celebration: false,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ));
  }
}

class _DataLaporan {
  const _DataLaporan({
    required this.daftarTransaksi,
    required this.penjualan,
    required this.jumlahTransaksi,
    required this.jumlah,
    required this.pemasukan,
    required this.pengeluaran,
    required this.net,
    required this.average,
    required this.daily,
    required this.produkTerlaris,
    required this.expenseByCategory,
  });

  final List<TransaksiPenjualan> daftarTransaksi;
  final double penjualan;
  final int jumlahTransaksi;
  final int jumlah;
  final double pemasukan;
  final double pengeluaran;
  final double net;
  final double average;
  final List<_KasHarian> daily;
  final List<ProdukTerlaris> produkTerlaris;
  final List<MapEntry<String, double>> expenseByCategory;

  factory _DataLaporan.from({
    required DateTimeRange rentang,
    required List<TransaksiPenjualan> daftarTransaksi,
    required List<CatatanKas> daftarCatatanKas,
    required List<ProdukTerlaris> produkTerlaris,
  }) {
    final penjualan = daftarTransaksi.fold<double>(
      0,
      (sum, transaksi) => sum + transaksi.total,
    );
    final jumlah = daftarTransaksi.fold<int>(
      0,
      (sum, transaksi) => sum + transaksi.totalJumlah,
    );
    final pemasukan = daftarCatatanKas
        .where((catatan) => catatan.jenis == JenisCatatanKas.pemasukan)
        .fold<double>(0, (sum, catatan) => sum + catatan.jumlah);
    final pengeluaran = daftarCatatanKas
        .where((catatan) => catatan.jenis == JenisCatatanKas.pengeluaran)
        .fold<double>(0, (sum, catatan) => sum + catatan.jumlah);

    final dailyMap = <int, _KasHarian>{};
    final start = DateTime(
      rentang.start.year,
      rentang.start.month,
      rentang.start.day,
    );
    final end = DateTime(rentang.end.year, rentang.end.month, rentang.end.day);
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      dailyMap[_dateKey(day)] = _KasHarian(day);
    }
    for (final transaksi in daftarTransaksi) {
      dailyMap[_dateKey(transaksi.dibuatPada)]?.pemasukan += transaksi.total;
    }
    for (final catatan in daftarCatatanKas) {
      final day = dailyMap[_dateKey(catatan.dibuatPada)];
      if (day == null) continue;
      if (catatan.jenis == JenisCatatanKas.pemasukan) {
        day.pemasukan += catatan.jumlah;
      } else {
        day.pengeluaran += catatan.jumlah;
      }
    }
    final daily = dailyMap.values.toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final expenseMap = <String, double>{};
    for (final catatan in daftarCatatanKas) {
      if (catatan.jenis != JenisCatatanKas.pengeluaran) continue;
      expenseMap.update(
        catatan.kategori,
        (value) => value + catatan.jumlah,
        ifAbsent: () => catatan.jumlah,
      );
    }
    final expenseByCategory = expenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _DataLaporan(
      daftarTransaksi: daftarTransaksi,
      penjualan: penjualan,
      jumlahTransaksi: daftarTransaksi.length,
      jumlah: jumlah,
      pemasukan: pemasukan,
      pengeluaran: pengeluaran,
      net: penjualan + pemasukan - pengeluaran,
      average: daftarTransaksi.isEmpty ? 0 : penjualan / daftarTransaksi.length,
      daily: daily,
      produkTerlaris: produkTerlaris,
      expenseByCategory: expenseByCategory,
    );
  }
}

int _dateKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;

class _KasHarian {
  _KasHarian(this.tanggal);
  final DateTime tanggal;
  double pemasukan = 0;
  double pengeluaran = 0;
}

class _KartuGrafik extends StatelessWidget {
  const _KartuGrafik({required this.days});

  final List<_KasHarian> days;

  @override
  Widget build(BuildContext context) {
    final maxValue = days.fold<double>(
      0,
      (current, day) => math.max(current, math.max(day.pemasukan, day.pengeluaran)),
    );
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WarnaAplikasi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Arus Kas Harian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: WarnaAplikasi.ink,
                  ),
                ),
              ),
              _TitikLegenda(color: WarnaAplikasi.success, label: 'Masuk'),
              const SizedBox(width: 10),
              _TitikLegenda(color: WarnaAplikasi.danger, label: 'Keluar'),
            ],
          ),
          const SizedBox(height: 14),
          if (days.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Belum ada data untuk periode ini.',
                  style: TextStyle(fontSize: 12, color: WarnaAplikasi.muted),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days
                      .map(
                        (day) => Tooltip(
                          message:
                              '${Tanggal.tanggal(day.tanggal)}\n'
                              'Masuk: ${Uang.format(day.pemasukan)}\n'
                              'Keluar: ${Uang.format(day.pengeluaran)}',
                          child: SizedBox(
                            width: 37,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _Batang(
                                      height: day.pemasukan <= 0
                                          ? 2
                                          : (day.pemasukan / safeMax) * 92,
                                      color: WarnaAplikasi.success,
                                    ),
                                    const SizedBox(width: 3),
                                    _Batang(
                                      height: day.pengeluaran <= 0
                                          ? 2
                                          : (day.pengeluaran / safeMax) * 92,
                                      color: WarnaAplikasi.danger,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  Tanggal.nomorHari(day.tanggal),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: WarnaAplikasi.ink,
                                  ),
                                ),
                                Text(
                                  Tanggal.singkatHari(day.tanggal),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: WarnaAplikasi.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Batang extends StatelessWidget {
  const _Batang({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _TitikLegenda extends StatelessWidget {
  const _TitikLegenda({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: WarnaAplikasi.muted),
        ),
      ],
    );
  }
}

class _KartuProdukTerlaris extends StatelessWidget {
  const _KartuProdukTerlaris({required this.daftarProduk});

  final List<ProdukTerlaris> daftarProduk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WarnaAplikasi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Terlaris',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: WarnaAplikasi.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (daftarProduk.isEmpty)
            const Text(
              'Belum ada produk terjual pada periode ini.',
              style: TextStyle(fontSize: 11.5, color: WarnaAplikasi.muted),
            )
          else
            ...daftarProduk.asMap().entries.map((catatan) {
              final index = catatan.key;
              final produk = catatan.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? WarnaAplikasi.primaryLight
                            : WarnaAplikasi.cream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: index == 0
                              ? WarnaAplikasi.primaryDark
                              : WarnaAplikasi.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produk.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: WarnaAplikasi.ink,
                            ),
                          ),
                          Text(
                            '${produk.jumlah} porsi terjual',
                            style: const TextStyle(
                              fontSize: 10,
                              color: WarnaAplikasi.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Uang.format(produk.pendapatan),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: WarnaAplikasi.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _KartuRincianPengeluaran extends StatelessWidget {
  const _KartuRincianPengeluaran({required this.daftarCatatan});

  final List<MapEntry<String, double>> daftarCatatan;

  @override
  Widget build(BuildContext context) {
    final maxValue = daftarCatatan.isEmpty ? 1.0 : daftarCatatan.first.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WarnaAplikasi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pengeluaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: WarnaAplikasi.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (daftarCatatan.isEmpty)
            const Text(
              'Belum ada pengeluaran pada periode ini.',
              style: TextStyle(fontSize: 11.5, color: WarnaAplikasi.muted),
            )
          else
            ...daftarCatatan.map(
              (catatan) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            catatan.key,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: WarnaAplikasi.ink,
                            ),
                          ),
                        ),
                        Text(
                          Uang.format(catatan.value),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: WarnaAplikasi.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: catatan.value / maxValue,
                        minHeight: 5,
                        backgroundColor: WarnaAplikasi.dangerSoft,
                        valueColor: const AlwaysStoppedAnimation(
                          WarnaAplikasi.danger,
                        ),
                      ),
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

class _UbinTransaksiTerakhir extends StatelessWidget {
  const _UbinTransaksiTerakhir({
    required this.transaksi,
    required this.onTap,
  });

  final TransaksiPenjualan transaksi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WarnaAplikasi.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 19,
                color: WarnaAplikasi.primaryDark,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaksi.nomor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: WarnaAplikasi.ink,
                      ),
                    ),
                    Text(
                      '${Tanggal.lengkap(transaksi.dibuatPada)} · '
                      '${transaksi.metodePembayaran}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: WarnaAplikasi.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Uang.format(transaksi.total),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: WarnaAplikasi.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  const _ChipFilter({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? WarnaAplikasi.primary : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? WarnaAplikasi.primary : WarnaAplikasi.border,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? Colors.white : WarnaAplikasi.muted,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : WarnaAplikasi.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


