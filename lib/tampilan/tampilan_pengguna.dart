import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../model/pengguna.dart';
import '../penyedia/penyedia_auth.dart';
import '../widget/keadaan_kosong.dart';

class TampilanPengguna extends StatefulWidget {
  const TampilanPengguna({super.key});

  @override
  State<TampilanPengguna> createState() => _StatusTampilanPengguna();
}

class _StatusTampilanPengguna extends State<TampilanPengguna> {
  bool _memuat = true;
  String? _galatMuat;
  List<Pengguna> _daftarPengguna = const [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galatMuat = null;
    });
    try {
      final data = await context.read<PenyediaAuth>().semuaPengguna();
      if (!mounted) return;
      setState(() {
        _daftarPengguna = data;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatMuat = 'Gagal memuat pengguna: $e';
        _memuat = false;
      });
    }
  }

  Future<void> _bukaForm({Pengguna? pengguna}) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogPengguna(pengguna: pengguna),
    );
    if (hasil == true) _muat();
  }

  Future<void> _alihAktif(Pengguna pengguna) async {
    final aktifBaru = !pengguna.aktif;
    final pesan = await context.read<PenyediaAuth>().simpanPengguna(
          id: pengguna.id,
          namaPengguna: pengguna.namaPengguna,
          namaLengkap: pengguna.namaLengkap,
          peran: pengguna.peran,
          aktif: aktifBaru,
        );
    if (!mounted) return;
    if (pesan != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(aktifBaru
            ? 'Pengguna ${pengguna.namaLengkap} diaktifkan.'
            : 'Pengguna ${pengguna.namaLengkap} dinonaktifkan.'),
      ),
    );
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<PenyediaAuth>();
    if (!auth.adalahAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Pengguna')),
        body: const Center(child: Text('Hanya admin yang dapat mengelola pengguna.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _muat,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah'),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _galatMuat != null
              ? KeadaanKosong(
                  icon: Icons.error_outline_rounded,
                  title: 'Gagal memuat',
                  message: _galatMuat!,
                  actionLabel: 'Coba Lagi',
                  onAction: _muat,
                )
              : _daftarPengguna.isEmpty
                  ? KeadaanKosong(
                      icon: Icons.group_outlined,
                      title: 'Belum ada pengguna',
                      message: 'Tambahkan akun kasir atau admin.',
                      actionLabel: 'Tambah Pengguna',
                      onAction: () => _bukaForm(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: _daftarPengguna.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = _daftarPengguna[i];
                        return _UbinPengguna(
                          pengguna: p,
                          padaUbah: () => _bukaForm(pengguna: p),
                          padaAlihAktif: () => _alihAktif(p),
                        );
                      },
                    ),
    );
  }
}

class _UbinPengguna extends StatelessWidget {
  const _UbinPengguna({
    required this.pengguna,
    required this.padaUbah,
    required this.padaAlihAktif,
  });

  final Pengguna pengguna;
  final VoidCallback padaUbah;
  final VoidCallback padaAlihAktif;

  @override
  Widget build(BuildContext context) {
    final aktif = pengguna.aktif;
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: WarnaAplikasi.border),
      ),
      leading: CircleAvatar(
        backgroundColor: aktif ? WarnaAplikasi.primaryLight : WarnaAplikasi.border,
        child: Icon(
          pengguna.adalahAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
          color: aktif ? WarnaAplikasi.primaryDark : WarnaAplikasi.muted,
          size: 20,
        ),
      ),
      title: Text(
        pengguna.namaLengkap,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: aktif ? WarnaAplikasi.ink : WarnaAplikasi.muted,
        ),
      ),
      subtitle: Text(
        '${pengguna.namaPengguna} • ${pengguna.adalahAdmin ? 'Admin' : 'Kasir'} • ${aktif ? 'Aktif' : 'Nonaktif'}',
        style: const TextStyle(fontSize: 12, color: WarnaAplikasi.muted),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'ubah') padaUbah();
          if (v == 'alih') padaAlihAktif();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'ubah', child: Text('Ubah')),
          PopupMenuItem(
            value: 'alih',
            child: Text(aktif ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
      onTap: padaUbah,
    );
  }
}

class _DialogPengguna extends StatefulWidget {
  const _DialogPengguna({this.pengguna});
  final Pengguna? pengguna;

  @override
  State<_DialogPengguna> createState() => _StatusDialogPengguna();
}

class _StatusDialogPengguna extends State<_DialogPengguna> {
  final _formulir = GlobalKey<FormState>();
  late final TextEditingController _namaPengguna;
  late final TextEditingController _namaLengkap;
  late final TextEditingController _pin;
  late String _peran;
  late bool _aktif;
  bool _menyimpan = false;

  bool get _modeUbah => widget.pengguna != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pengguna;
    _namaPengguna = TextEditingController(text: p?.namaPengguna ?? '');
    _namaLengkap = TextEditingController(text: p?.namaLengkap ?? '');
    _pin = TextEditingController();
    _peran = p?.peran ?? 'kasir';
    _aktif = p?.aktif ?? true;
  }

  @override
  void dispose() {
    _namaPengguna.dispose();
    _namaLengkap.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formulir.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    final pesan = await context.read<PenyediaAuth>().simpanPengguna(
          id: widget.pengguna?.id,
          namaPengguna: _namaPengguna.text,
          namaLengkap: _namaLengkap.text,
          peran: _peran,
          pin: _pin.text.trim().isEmpty ? null : _pin.text,
          aktif: _aktif,
        );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (pesan != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_modeUbah ? 'Ubah Pengguna' : 'Tambah Pengguna'),
      content: SingleChildScrollView(
        child: Form(
          key: _formulir,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaPengguna,
                decoration: const InputDecoration(labelText: 'Nama Pengguna'),
                enabled: !_modeUbah,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaLengkap,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _peran,
                decoration: const InputDecoration(labelText: 'Peran'),
                items: const [
                  DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _peran = v ?? 'kasir'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pin,
                decoration: InputDecoration(
                  labelText: _modeUbah ? 'PIN Baru (opsional)' : 'PIN',
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (!_modeUbah && (v == null || v.trim().isEmpty)) {
                    return 'PIN wajib diisi';
                  }
                  if (v != null && v.trim().isNotEmpty && v.trim().length < 4) {
                    return 'PIN minimal 4 digit';
                  }
                  return null;
                },
              ),
              if (_modeUbah) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: _aktif,
                  onChanged: (v) => setState(() => _aktif = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _menyimpan ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _menyimpan ? null : _simpan,
          child: Text(_menyimpan ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}
