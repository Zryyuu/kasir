import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../model/pengguna.dart';
import '../penyedia/penyedia_auth.dart';

class TampilanMasuk extends StatefulWidget {
  const TampilanMasuk({super.key});

  @override
  State<TampilanMasuk> createState() => _StatusTampilanMasuk();
}

class _StatusTampilanMasuk extends State<TampilanMasuk> {
  List<Pengguna> _daftarPengguna = [];
  int? _idPenggunaDipilih;
  final _pengendaliPin = TextEditingController();
  bool _memuatPengguna = true;
  String? _galatMuat;
  String? _galatLokal;

  @override
  void initState() {
    super.initState();
    _muatPengguna();
  }

  Future<void> _muatPengguna() async {
    setState(() {
      _memuatPengguna = true;
      _galatMuat = null;
    });
    try {
      final daftarPengguna = await context.read<PenyediaAuth>().penggunaAktif();
      if (!mounted) return;
      setState(() {
        _daftarPengguna = daftarPengguna;
        _idPenggunaDipilih = daftarPengguna.isNotEmpty ? daftarPengguna.first.id : null;
        _memuatPengguna = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _daftarPengguna = const [];
        _idPenggunaDipilih = null;
        _memuatPengguna = false;
        _galatMuat = 'Gagal memuat pengguna: $e';
      });
    }
  }

  @override
  void dispose() {
    _pengendaliPin.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final idPengguna = _idPenggunaDipilih;
    if (idPengguna == null) {
      setState(() => _galatLokal = 'Pilih pengguna terlebih dahulu.');
      return;
    }
    final pin = _pengendaliPin.text.trim();
    if (pin.isEmpty) {
      setState(() => _galatLokal = 'Masukkan PIN.');
      return;
    }
    if (pin.length < 4) {
      setState(() => _galatLokal = 'PIN minimal 4 digit.');
      return;
    }
    final user = _daftarPengguna.where((u) => u.id == idPengguna).firstOrNull;
    if (user == null) {
      setState(() => _galatLokal = 'Pengguna tidak ditemukan.');
      return;
    }
    setState(() => _galatLokal = null);
    await context.read<PenyediaAuth>().masuk(user.namaPengguna, pin);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<PenyediaAuth>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 56, color: WarnaAplikasi.primaryDark),
                  const SizedBox(height: 12),
                  const Text(
                    'Sinar Kasir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: WarnaAplikasi.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masuk untuk mulai transaksi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WarnaAplikasi.muted),
                  ),
                  const SizedBox(height: 28),
                  if (_memuatPengguna)
                    const Center(child: CircularProgressIndicator())
                  else if (_galatMuat != null) ...[
                    Text(
                      _galatMuat!,
                      style: const TextStyle(color: WarnaAplikasi.danger),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _muatPengguna,
                      child: const Text('Coba Lagi'),
                    ),
                  ] else if (_daftarPengguna.isEmpty) ...[
                    const Text(
                      'Belum ada pengguna aktif. Coba reset data atau buat pengguna.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WarnaAplikasi.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _muatPengguna,
                      child: const Text('Muat Ulang'),
                    ),
                  ] else ...[
                    DropdownButtonFormField<int>(
                      initialValue: _idPenggunaDipilih,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pengguna',
                        border: OutlineInputBorder(),
                      ),
                      items: _daftarPengguna
                          .map(
                            (u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Text(
                                '${u.namaLengkap} (${u.adalahAdmin ? 'Admin' : 'Kasir'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _idPenggunaDipilih = v;
                        _galatLokal = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pengendaliPin,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        border: const OutlineInputBorder(),
                        counterText: '',
                        errorText: _galatLokal ?? auth.galat,
                      ),
                      onChanged: (_) {
                        if (_galatLokal != null) {
                          setState(() => _galatLokal = null);
                        }
                        if (auth.galat != null) {
                          auth.bersihkanGalat();
                        }
                      },
                      onSubmitted: (_) => _kirim(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: auth.memuat ? null : _kirim,
                      child: auth.memuat
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('MASUK'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


