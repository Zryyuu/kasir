import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/catatan_kas.dart';
import '../penyedia/penyedia_catatan_kas.dart';

Future<void> tampilkanLembarCatatanKas(
  BuildContext context, {
  CatatanKas? catatan,
  required JenisCatatanKas jenis,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LembarCatatanKas(catatan: catatan, jenis: jenis),
  );
}

class LembarCatatanKas extends StatefulWidget {
  const LembarCatatanKas({super.key, this.catatan, required this.jenis});

  final CatatanKas? catatan;
  final JenisCatatanKas jenis;

  @override
  State<LembarCatatanKas> createState() => _StatusLembarCatatanKas();
}

class _StatusLembarCatatanKas extends State<LembarCatatanKas> {
  late final TextEditingController _pengendaliJumlah;
  late final TextEditingController _pengendaliKeterangan;
  late String _kategoriDipilih;
  late DateTime _tanggal;
  String? _galat;
  bool _menyimpan = false;

  bool get _sedangEdit => widget.catatan != null;

  List<String> get _daftarKategori => widget.jenis == JenisCatatanKas.pengeluaran
      ? kKategoriPengeluaran
      : kSumberPemasukan;

  @override
  void initState() {
    super.initState();
    final catatan = widget.catatan;
    _pengendaliJumlah = TextEditingController(
      text: catatan == null ? '' : Uang.polos(catatan.jumlah),
    );
    _pengendaliKeterangan = TextEditingController(text: catatan?.keterangan ?? '');
    _kategoriDipilih = catatan?.kategori ?? _daftarKategori.first;
    _tanggal = catatan?.dibuatPada ?? DateTime.now();
  }

  @override
  void dispose() {
    _pengendaliJumlah.dispose();
    _pengendaliKeterangan.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _tanggal = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _tanggal.hour,
        _tanggal.minute,
      );
    });
  }

  Future<void> _simpan() async {
    final jumlah = Uang.urai(_pengendaliJumlah.text);
    if (jumlah <= 0) {
      setState(() => _galat = 'Nominal harus lebih dari 0.');
      return;
    }
    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    final provider = context.read<PenyediaCatatanKas>();
    final keterangan = _pengendaliKeterangan.text.trim();
    try {
      if (_sedangEdit) {
        await provider.perbarui(
          widget.catatan!.salinDengan(
            kategori: _kategoriDipilih,
            jumlah: jumlah,
            keterangan: keterangan,
            hapusKeterangan: keterangan.isEmpty,
            dibuatPada: _tanggal,
          ),
        );
      } else {
        await provider.tambah(
          jenis: widget.jenis,
          kategori: _kategoriDipilih,
          jumlah: jumlah,
          keterangan: keterangan,
          dibuatPada: _tanggal,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final label = widget.jenis == JenisCatatanKas.pengeluaran
          ? 'Pengeluaran'
          : 'Kas Masuk';
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _sedangEdit
                ? 'Catatan $label diperbarui.'
                : '$label ${Uang.format(jumlah)} dicatat.',
          ),
        ),
      );
    } catch (galat) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Gagal menyimpan: $galat';
      });
    }
  }

  Future<void> _hapus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text(
          '${widget.catatan!.kategori} sebesar '
          '${Uang.format(widget.catatan!.jumlah)} akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WarnaAplikasi.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _menyimpan = true);
    try {
      await context.read<PenyediaCatatanKas>().hapus(widget.catatan!.id!);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Catatan dihapus.')));
    } catch (galat) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Gagal menghapus: $galat';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adalahPengeluaran = widget.jenis == JenisCatatanKas.pengeluaran;
    final color = adalahPengeluaran ? WarnaAplikasi.danger : WarnaAplikasi.success;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WarnaAplikasi.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _sedangEdit
                      ? 'Edit ${adalahPengeluaran ? 'Pengeluaran' : 'Kas Masuk'}'
                      : adalahPengeluaran
                      ? 'Tambah Pengeluaran'
                      : 'Tambah Kas Masuk',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WarnaAplikasi.ink,
                      ),
                    ),
                  ),
                  if (_sedangEdit)
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: _menyimpan ? null : _hapus,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: WarnaAplikasi.danger,
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
                controller: _pengendaliJumlah,
                autofocus: !_sedangEdit,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  PemformatRibuan(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: WarnaAplikasi.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _daftarKategori.map((kategori) {
                  final selected = kategori == _kategoriDipilih;
                  return ChoiceChip(
                    label: Text(kategori),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _kategoriDipilih = kategori;
                    }),
                    selectedColor: color.withValues(alpha: 0.13),
                    side: BorderSide(
                      color: selected
                          ? color.withValues(alpha: 0.45)
                          : WarnaAplikasi.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : WarnaAplikasi.ink,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pengendaliKeterangan,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: beli minyak goreng',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WarnaAplikasi.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: WarnaAplikasi.muted,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WarnaAplikasi.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Tanggal.tanggal(_tanggal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: WarnaAplikasi.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_galat != null) ...[
                const SizedBox(height: 12),
                Text(
                  _galat!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WarnaAplikasi.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: _menyimpan ? null : _simpan,
                child: Text(_menyimpan ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


