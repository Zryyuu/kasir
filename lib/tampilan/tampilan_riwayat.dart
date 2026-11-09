import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/transaksi_penjualan.dart';
import '../penyedia/penyedia_transaksi.dart';
import '../widget/keadaan_kosong.dart';
import '../widget/lembar_struk.dart';

enum _PeriodeRiwayat { today, week, month, custom }

class TampilanRiwayat extends StatefulWidget {
  const TampilanRiwayat({super.key});

  @override
  State<TampilanRiwayat> createState() => _StatusTampilanRiwayat();
}

class _StatusTampilanRiwayat extends State<TampilanRiwayat> {
  final _pengendaliPencarian = TextEditingController();
  Timer? _penunda;

  _PeriodeRiwayat _periode = _PeriodeRiwayat.month;
  DateTimeRange? _rentangKhusus;
  String? _metodePembayaran;
  List<TransaksiPenjualan> _daftarTransaksi = [];
  bool _memuat = true;
  int _idPermintaan = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _muat();
    });
  }

  @override
  void dispose() {
    _penunda?.cancel();
    _pengendaliPencarian.dispose();
    super.dispose();
  }

  DateTimeRange _rentang() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_periode) {
      case _PeriodeRiwayat.today:
        return DateTimeRange(start: today, end: now);
      case _PeriodeRiwayat.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: now,
        );
      case _PeriodeRiwayat.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _PeriodeRiwayat.custom:
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
      helpText: 'Pilih rentang tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _rentangKhusus = picked;
      _periode = _PeriodeRiwayat.custom;
    });
    _muat();
  }

  Future<void> _muat() async {
    final idPermintaan = ++_idPermintaan;
    if (mounted) setState(() => _memuat = true);
    final rentang = _rentang();
    try {
      final daftarTransaksi = await context.read<PenyediaTransaksi>().berdasarkanRentang(
        rentang.start,
        rentang.end,
        kataKunci: _pengendaliPencarian.text,
        metodePembayaran: _metodePembayaran,
      );
      if (!mounted || idPermintaan != _idPermintaan) return;
      setState(() {
        _daftarTransaksi = daftarTransaksi;
        _memuat = false;
      });
    } catch (galat) {
      if (!mounted || idPermintaan != _idPermintaan) return;
      setState(() => _memuat = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat: $galat')));
    }
  }

  void _saatPencarianBerubah(String value) {
    _penunda?.cancel();
    _penunda = Timer(const Duration(milliseconds: 350), _muat);
  }

  void _pilihPeriode(_PeriodeRiwayat periode) {
    if (periode == _PeriodeRiwayat.custom) {
      _pilihRentangKhusus();
      return;
    }
    setState(() => _periode = periode);
    _muat();
  }

  void _pilihMetode(String? metode) {
    setState(() => _metodePembayaran = metode);
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final rentang = _rentang();
    final total = _daftarTransaksi.fold<double>(
      0,
      (sum, transaksi) => sum + transaksi.total,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TextField(
              controller: _pengendaliPencarian,
              onChanged: (value) {
                setState(() {});
                _saatPencarianBerubah(value);
              },
              decoration: InputDecoration(
                hintText: 'Cari nomor transaksi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _pengendaliPencarian.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _pengendaliPencarian.clear();
                          setState(() {});
                          _muat();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _ChipFilter(
                  label: 'Hari Ini',
                  selected: _periode == _PeriodeRiwayat.today,
                  onTap: () => _pilihPeriode(_PeriodeRiwayat.today),
                ),
                const SizedBox(width: 7),
                _ChipFilter(
                  label: '7 Hari',
                  selected: _periode == _PeriodeRiwayat.week,
                  onTap: () => _pilihPeriode(_PeriodeRiwayat.week),
                ),
                const SizedBox(width: 7),
                _ChipFilter(
                  label: 'Bulan Ini',
                  selected: _periode == _PeriodeRiwayat.month,
                  onTap: () => _pilihPeriode(_PeriodeRiwayat.month),
                ),
                const SizedBox(width: 7),
                _ChipFilter(
                  label: 'Pilih Tanggal',
                  selected: _periode == _PeriodeRiwayat.custom,
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _pilihPeriode(_PeriodeRiwayat.custom),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _ChipFilterMetode(
                  label: 'Semua',
                  selected: _metodePembayaran == null,
                  onTap: () => _pilihMetode(null),
                ),
                const SizedBox(width: 7),
                _ChipFilterMetode(
                  label: 'Tunai',
                  selected: _metodePembayaran == kPembayaranTunai,
                  onTap: () => _pilihMetode(kPembayaranTunai),
                ),
                const SizedBox(width: 7),
                _ChipFilterMetode(
                  label: 'QRIS',
                  selected: _metodePembayaran == kPembayaranQris,
                  onTap: () => _pilihMetode(kPembayaranQris),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Text(
                  '${_daftarTransaksi.length} transaksi',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: WarnaAplikasi.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  Uang.format(total),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: WarnaAplikasi.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          if (_memuat && _daftarTransaksi.isNotEmpty)
            const SizedBox(
              height: 2,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Expanded(
            child: _memuat && _daftarTransaksi.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _daftarTransaksi.isEmpty
                ? KeadaanKosong(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi',
                    message: 'Tidak ada transaksi pada filter ini. Coba ubah periode atau mulai transaksi baru.',
                  )
                : RefreshIndicator(
                    color: WarnaAplikasi.primary,
                    onRefresh: _muat,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                      itemCount: _daftarTransaksi.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final transaksi = _daftarTransaksi[index];
                        return _UbinRiwayat(
                          transaksi: transaksi,
                          onTap: () => tampilkanLembarStruk(
                            context,
                            transaksi,
                            celebration: false,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (_periode == _PeriodeRiwayat.custom)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${Tanggal.tanggal(rentang.start)} - ${Tanggal.tanggal(rentang.end)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: WarnaAplikasi.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ));
  }
}

class _UbinRiwayat extends StatelessWidget {
  const _UbinRiwayat({required this.transaksi, required this.onTap});

  final TransaksiPenjualan transaksi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adalahTunai = transaksi.metodePembayaran == kPembayaranTunai;
    final warnaMetode = adalahTunai ? WarnaAplikasi.primaryDark : WarnaAplikasi.info;
    final lembutMetode = adalahTunai ? WarnaAplikasi.cream : WarnaAplikasi.infoSoft;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WarnaAplikasi.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: lembutMetode,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  adalahTunai ? Icons.payments_outlined : Icons.qr_code_2_rounded,
                  size: 21,
                  color: warnaMetode,
                ),
              ),
              const SizedBox(width: 11),
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
                        fontWeight: FontWeight.w800,
                        color: WarnaAplikasi.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Tanggal.lengkap(transaksi.dibuatPada)} · '
                      '${transaksi.metodePembayaran}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: WarnaAplikasi.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaksi.jumlahItem} varian · '
                      '${transaksi.totalJumlah} porsi',
                      style: const TextStyle(
                        fontSize: 10,
                        color: WarnaAplikasi.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Uang.format(transaksi.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: WarnaAplikasi.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: lembutMetode,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      transaksi.metodePembayaran,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: warnaMetode,
                      ),
                    ),
                  ),
                ],
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

class _ChipFilterMetode extends StatelessWidget {
  const _ChipFilterMetode({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? WarnaAplikasi.ink : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? WarnaAplikasi.ink : WarnaAplikasi.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : WarnaAplikasi.muted,
          ),
        ),
      ),
    );
  }
}


