import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/item_keranjang.dart';
import '../model/tambahan.dart';
import '../model/produk.dart';
import '../penyedia/penyedia_keranjang.dart';
import '../penyedia/penyedia_pengaturan.dart';
import '../penyedia/penyedia_tambahan.dart';

Future<void> tampilkanLembarTambahan(BuildContext context, Produk produk) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LembarTambahan(produk: produk),
  );
}

class LembarTambahan extends StatefulWidget {
  const LembarTambahan({super.key, required this.produk});
  final Produk produk;

  @override
  State<LembarTambahan> createState() => _StatusLembarTambahan();
}

class _StatusLembarTambahan extends State<LembarTambahan> {
  final Set<Tambahan> _dipilih = {};
  bool _modeCampur = false;

  @override
  Widget build(BuildContext context) {
    final daftarTambahan = context.watch<PenyediaTambahan>().tambahanAktif;
    final hargaMix = context.watch<PenyediaPengaturan>().hargaMixVarian;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    double harga = widget.produk.harga;
    if (_dipilih.isEmpty) {
      harga = widget.produk.harga;
    } else if (_dipilih.length == 1) {
      harga = widget.produk.harga + _dipilih.first.harga;
    } else if (_dipilih.length >= 2) {
      harga = hargaMix;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.produk.nama,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: WarnaAplikasi.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dipilih.isEmpty
                              ? 'Original • ${Uang.format(widget.produk.harga)}'
                              : _dipilih.length == 1
                              ? '${_dipilih.first.nama} • ${Uang.format(harga)}'
                              : 'Mix Varian (${_dipilih.length} topping) • ${Uang.format(harga)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: WarnaAplikasi.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ChipOpsi(
                      label: 'Tanpa Topping',
                      selected: _dipilih.isEmpty,
                      onTap: () => setState(() => _dipilih.clear()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChipOpsi(
                      label: 'Mix Varian (max 2)',
                      selected: _modeCampur && _dipilih.length >= 2,
                      onTap: () => setState(() {
                        _modeCampur = true;
                        if (_dipilih.length > 2) {
                          _dipilih.clear();
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daftarTambahan.map((m) {
                    final selected = _dipilih.contains(m);
                    return ChoiceChip(
                      label: Text(
                        _dipilih.length == 1 && !selected
                            ? '${m.nama} (+${Uang.format(m.harga)})'
                            : _dipilih.isEmpty
                            ? '${m.nama} (+${Uang.format(m.harga)})'
                            : m.nama,
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (_modeCampur || _dipilih.isNotEmpty) {
                            if (selected) {
                              _dipilih.remove(m);
                              if (_dipilih.isEmpty) _modeCampur = false;
                              return;
                            }
                            if (_dipilih.length >= 2) {
                              // replace? keep max 2
                              _dipilih.clear();
                            }
                            _dipilih.add(m);
                            if (_dipilih.length >= 2) _modeCampur = true;
                            return;
                          }
                          if (selected) {
                            _dipilih.remove(m);
                          } else {
                            _dipilih.clear();
                            _dipilih.add(m);
                          }
                        });
                      },
                      selectedColor: WarnaAplikasi.primary.withValues(alpha: 0.13),
                      side: BorderSide(
                        color: selected
                            ? WarnaAplikasi.primary.withValues(alpha: 0.45)
                            : WarnaAplikasi.border,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.ink,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: WarnaAplikasi.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  final tambahan = _dipilih
                      .map(
                        (m) => TambahanItemKeranjang(
                          idTambahan: m.id,
                          nama: m.nama,
                          harga: m.harga,
                        ),
                      )
                      .toList();
                  final keranjang = context.read<PenyediaKeranjang>();
                  String? err;
                  if (_dipilih.length >= 2) {
                    // Mix varian: total sudah Rp18.000, jadi harga topping
                    // tidak ditambahkan lagi agar sesuai dengan yang tampil.
                    final mixMods = tambahan
                        .take(2)
                        .map(
                          (m) => TambahanItemKeranjang(
                            idTambahan: m.idTambahan,
                            nama: m.nama,
                            harga: 0,
                          ),
                        )
                        .toList();
                    err = keranjang.tambahDenganTambahan(
                      Produk(
                        id: widget.produk.id,
                        nama: widget.produk.nama,
                        harga: hargaMix,
                        stok: widget.produk.stok,
                        aktif: widget.produk.aktif,
                        dibuatPada: widget.produk.dibuatPada,
                      ),
                      mixMods,
                    );
                  } else {
                    err = keranjang.tambahDenganTambahan(widget.produk, tambahan);
                  }
                  if (err != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(err)));
                    return;
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _dipilih.isEmpty
                            ? '${widget.produk.nama} ditambahkan'
                            : 'Ditambahkan ke keranjang',
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                },
                child: Text('Tambah • ${Uang.format(harga)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipOpsi extends StatelessWidget {
  const _ChipOpsi({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? WarnaAplikasi.primary.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? WarnaAplikasi.primary.withValues(alpha: 0.45) : WarnaAplikasi.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.ink,
          ),
        ),
      ),
    );
  }
}


