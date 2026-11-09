import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../data/basis_data.dart';
import '../model/produk.dart';
import '../penyedia/penyedia_auth.dart';
import '../penyedia/penyedia_catatan_kas.dart';
import '../penyedia/penyedia_katalog.dart';
import '../layanan/layanan_stok.dart';
import '../widget/keadaan_kosong.dart';

class TampilanProduk extends StatefulWidget {
  const TampilanProduk({super.key});

  @override
  State<TampilanProduk> createState() => _StatusTampilanProduk();
}

class _StatusTampilanProduk extends State<TampilanProduk> {
  String _pencarian = '';
  final _pengendaliPencarian = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PenyediaKatalog>().load();
    });
  }

  @override
  void dispose() {
    _pengendaliPencarian.dispose();
    super.dispose();
  }

  List<Produk> _filter(List<Produk> daftarProduk) {
    final q = _pencarian.trim().toLowerCase();
    if (q.isEmpty) return daftarProduk;
    return daftarProduk
        .where((produk) => produk.nama.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _bukaForm({Produk? produk}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LembarFormProduk(produk: produk),
    );
  }

  Future<void> _bukaStok(Produk produk) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LembarStok(produk: produk),
    );
  }

  Future<void> _alihkanAktif(Produk produk) async {
    final deactivating = produk.aktif;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deactivating ? 'Nonaktifkan Produk?' : 'Aktifkan Produk?'),
        content: Text(
          deactivating
              ? '${produk.nama} tidak akan muncul di halaman Kasir. '
                    'Riwayat transaksi lama tetap aman.'
              : '${produk.nama} akan muncul kembali di halaman Kasir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(deactivating ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<PenyediaKatalog>().aturAktif(
      produk.id!,
      !produk.aktif,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adalahAdmin = context.watch<PenyediaAuth>().adalahAdmin;
    if (!adalahAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produk / Varian')),
        body: const Center(
          child: Text('Hanya admin yang dapat mengelola produk.'),
        ),
      );
    }

    final catalog = context.watch<PenyediaKatalog>();
    final daftarProduk = _filter(catalog.daftarProduk);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk / Varian'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              controller: _pengendaliPencarian,
              onChanged: (value) => setState(() => _pencarian = value),
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: catalog.memuat && catalog.daftarProduk.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : daftarProduk.isEmpty
                ? KeadaanKosong(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada produk',
                    message: 'Tambahkan varian pisang dan atur stok porsinya.',
                    actionLabel: 'Tambah Produk',
                    onAction: () => _bukaForm(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: daftarProduk.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final produk = daftarProduk[index];
                      return _UbinProduk(
                        produk: produk,
                        onEdit: () => _bukaForm(produk: produk),
                        onStock: () => _bukaStok(produk),
                        onToggleActive: () => _alihkanAktif(produk),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: WarnaAplikasi.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}

class _UbinProduk extends StatelessWidget {
  const _UbinProduk({
    required this.produk,
    required this.onEdit,
    required this.onStock,
    required this.onToggleActive,
  });

  final Produk produk;
  final VoidCallback onEdit;
  final VoidCallback onStock;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final statusColor = !produk.aktif
        ? WarnaAplikasi.muted
        : produk.stokHabis
        ? WarnaAplikasi.danger
        : produk.stokRendah
        ? WarnaAplikasi.warning
        : WarnaAplikasi.success;

    return Opacity(
      opacity: produk.aktif ? 1 : 0.65,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WarnaAplikasi.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WarnaAplikasi.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: WarnaAplikasi.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              produk.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: WarnaAplikasi.ink,
                              ),
                            ),
                          ),
                          if (!produk.aktif)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF2F7),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                'NONAKTIF',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: WarnaAplikasi.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Uang.format(produk.harga)} · Stok ${produk.stok} porsi',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: WarnaAplikasi.muted,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'ubah':
                        onEdit();
                        break;
                      case 'stok':
                        onStock();
                        break;
                      case 'toggle':
                        onToggleActive();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'ubah',
                      child: Text('Ubah produk'),
                    ),
                    const PopupMenuItem(
                      value: 'stok',
                      child: Text('Atur stok & alasan'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(produk.aktif ? 'Nonaktifkan' : 'Aktifkan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LembarFormProduk extends StatefulWidget {
  const LembarFormProduk({super.key, this.produk});

  final Produk? produk;

  @override
  State<LembarFormProduk> createState() => _StatusLembarFormProduk();
}

class _StatusLembarFormProduk extends State<LembarFormProduk> {

  late final TextEditingController _pengendaliNama;
  late final TextEditingController _pengendaliHarga;
  late final TextEditingController _pengendaliStok;
  String? _galat;
  bool _menyimpan = false;

  bool get _sedangEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final produk = widget.produk;
    _pengendaliNama = TextEditingController(text: produk?.nama ?? '');
    _pengendaliHarga = TextEditingController(
      text: produk == null ? '' : Uang.polos(produk.harga),
    );
    _pengendaliStok = TextEditingController(
      text: produk?.stok.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _pengendaliNama.dispose();
    _pengendaliHarga.dispose();
    _pengendaliStok.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final nama = _pengendaliNama.text.trim();
    final harga = Uang.urai(_pengendaliHarga.text);
    final stok = int.tryParse(_pengendaliStok.text.trim()) ?? 0;

    if (nama.isEmpty) {
      setState(() => _galat = 'Nama produk tidak boleh kosong.');
      return;
    }
    if (harga <= 0) {
      setState(() => _galat = 'Harga produk harus lebih dari 0.');
      return;
    }
    if (!_sedangEdit && stok < 0) {
      setState(() => _galat = 'Stok tidak boleh negatif.');
      return;
    }

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    final catalog = context.read<PenyediaKatalog>();
    try {
      if (_sedangEdit) {
        await catalog.perbaruiProduk(
          widget.produk!.salinDengan(nama: nama, harga: harga),
        );
      } else {
        await catalog.tambahProduk(
          nama: nama,
          harga: harga,
          stok: stok,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (galat) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Gagal menyimpan produk: $galat';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _sedangEdit ? 'Ubah produk' : 'Tambah Produk',
                      style: const TextStyle(
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
                controller: _pengendaliNama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk / Varian',
                  hintText: 'Contoh: Pisang Keju Susu',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pengendaliHarga,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PemformatRibuan(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual',
                        prefixText: 'Rp',
                      ),
                    ),
                  ),
                  if (!_sedangEdit) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _pengendaliStok,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal',
                          suffixText: 'porsi',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_sedangEdit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WarnaAplikasi.infoSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: WarnaAplikasi.info.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: WarnaAplikasi.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stok saat ini: ${widget.produk!.stok} porsi. '
                          'Ubah stok lewat menu "Atur stok & alasan" agar '
                          'alasan perubahan tercatat.',
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
                onPressed: _menyimpan ? null : _simpan,
                child: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Produk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LembarStok extends StatefulWidget {
  const LembarStok({super.key, required this.produk});

  final Produk produk;

  @override
  State<LembarStok> createState() => _StatusLembarStok();
}

class _StatusLembarStok extends State<LembarStok> {
  final _pengendaliJumlah = TextEditingController(text: '10');
  final _pengendaliKeterangan = TextEditingController();
  bool _menambah = true;
  String _alasan = kAlasanTambahStok.first;
  String? _galat;
  bool _menyimpan = false;

  List<String> get _daftarAlasan =>
      _menambah ? kAlasanTambahStok : kAlasanKurangStok;

  bool get _adalahKerugian => !_menambah && kAlasanKerugianStok.contains(_alasan);

  int get _jumlah => int.tryParse(_pengendaliJumlah.text.trim()) ?? 0;

  double get _jumlahKerugian => _adalahKerugian ? _jumlah * widget.produk.harga : 0;

  @override
  void dispose() {
    _pengendaliJumlah.dispose();
    _pengendaliKeterangan.dispose();
    super.dispose();
  }

  void _aturMode(bool increase) {
    setState(() {
      _menambah = increase;
      _alasan =
          (increase ? kAlasanTambahStok : kAlasanKurangStok).first;
      _galat = null;
    });
  }

  Future<void> _simpan() async {
    final jumlah = _jumlah;
    if (jumlah <= 0) {
      setState(() => _galat = 'Jumlah stok harus lebih dari 0.');
      return;
    }
    if (!_menambah && jumlah > widget.produk.stok) {
      setState(() => _galat = 'Stok tidak boleh kurang dari 0.');
      return;
    }
    final catalog = context.read<PenyediaKatalog>();
    final kas = context.read<PenyediaCatatanKas>();
    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    try {
      final hasil = await LayananStok(BasisData.instance).sesuaikanStok(
        produk: widget.produk,
        delta: _menambah ? jumlah : -jumlah,
        alasan: _alasan,
        keterangan: _pengendaliKeterangan.text,
      );
      await catalog.load();
      if (hasil.adalahKerugian) {
        await kas.load();
      }
      if (!mounted) return;
      final message = hasil.adalahKerugian
          ? 'Stok ${hasil.alasan.toLowerCase()}: ${hasil.jumlah} porsi. '
                'Kerugian ${Uang.format(hasil.jumlahKerugian)} dicatat.'
          : 'Stok diperbarui (${hasil.alasan}).';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (galat) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = galat.toString();
      });
    }
  }

  void _aturJumlah(int jumlah) {
    _pengendaliJumlah.text = jumlah.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                widget.produk.nama,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: WarnaAplikasi.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stok saat ini: ${widget.produk.stok} porsi',
                style: const TextStyle(fontSize: 12, color: WarnaAplikasi.muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ChipModeStok(
                      label: 'Tambah',
                      icon: Icons.add_rounded,
                      selected: _menambah,
                      onTap: () => _aturMode(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChipModeStok(
                      label: 'Kurangi',
                      icon: Icons.remove_rounded,
                      selected: !_menambah,
                      onTap: () => _aturMode(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pengendaliJumlah,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  suffixText: 'porsi',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 20, 50].map((jumlah) {
                  return InkWell(
                    onTap: () => _aturJumlah(jumlah),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: WarnaAplikasi.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: WarnaAplikasi.border),
                      ),
                      child: Text(
                        '${_menambah ? '+' : '-'}$jumlah',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: WarnaAplikasi.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Alasan Perubahan',
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _alasan,
                    isDense: true,
                    isExpanded: true,
                    items: _daftarAlasan
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _alasan = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pengendaliKeterangan,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: jatuh saat pengiriman',
                ),
              ),
              if (_adalahKerugian) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: WarnaAplikasi.warningSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: WarnaAplikasi.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: WarnaAplikasi.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kerugian ${Uang.format(_jumlahKerugian)} akan dicatat '
                          'sebagai pengeluaran.',
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
              if (_galat != null) ...[
                const SizedBox(height: 10),
                Text(
                  _galat!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WarnaAplikasi.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _menyimpan ? null : _simpan,
                child: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Perubahan Stok'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipModeStok extends StatelessWidget {
  const _ChipModeStok({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? WarnaAplikasi.primary.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? WarnaAplikasi.primary : WarnaAplikasi.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.muted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





