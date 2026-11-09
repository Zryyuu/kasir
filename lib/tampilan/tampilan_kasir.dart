import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../data/basis_data.dart';
import '../model/produk.dart';
import '../penyedia/penyedia_auth.dart';
import '../penyedia/penyedia_keranjang.dart';
import '../penyedia/penyedia_katalog.dart';
import '../penyedia/penyedia_transaksi.dart';
import '../widget/lembar_keranjang.dart';
import '../widget/keadaan_kosong.dart';
import '../widget/kartu_produk.dart';
import '../widget/lembar_struk.dart';
import '../widget/lembar_tambahan.dart';
import 'tampilan_produk.dart';

class TampilanKasir extends StatefulWidget {
  const TampilanKasir({super.key});

  @override
  State<TampilanKasir> createState() => _StatusTampilanKasir();
}

class _StatusTampilanKasir extends State<TampilanKasir> {
  String _pencarian = '';
  final _pengendaliPencarian = TextEditingController();

  @override
  void dispose() {
    _pengendaliPencarian.dispose();
    super.dispose();
  }

  List<Produk> _filter(List<Produk> daftarProduk) {
    final q = _pencarian.trim().toLowerCase();
    var list = daftarProduk.where((p) => p.aktif).toList();
    if (q.isNotEmpty) {
      list = list.where((p) => p.nama.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) {
      final aOut = a.stokHabis ? 1 : 0;
      final bOut = b.stokHabis ? 1 : 0;
      if (aOut != bOut) return aOut.compareTo(bOut);
      return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
    });
    return list;
  }

  Future<void> _bukaKeranjang() async {
    final keranjang = context.read<PenyediaKeranjang>();
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong.')));
      return;
    }
    final transaksi = await LembarKeranjang.show(
      context,
      keranjang: keranjang,
      catalog: context.read<PenyediaKatalog>(),
      db: BasisData.instance,
    );
    if (transaksi == null || !mounted) return;
    await Future.wait([
      context.read<PenyediaKatalog>().load(),
      context.read<PenyediaTransaksi>().muatTerbaru(),
    ]);
    if (!mounted) return;
    await tampilkanLembarStruk(context, transaksi);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<PenyediaKatalog>();
    final keranjang = context.watch<PenyediaKeranjang>();
    final adalahAdmin = context.watch<PenyediaAuth>().adalahAdmin;
    final daftarProduk = _filter(catalog.produkAktif);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          TextButton.icon(
            onPressed: keranjang.clear,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Kosongkan'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              controller: _pengendaliPencarian,
              onChanged: (value) => setState(() => _pencarian = value),
              decoration: InputDecoration(
                hintText: 'Cari varian produk...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _pencarian.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _pengendaliPencarian.clear();
                          setState(() => _pencarian = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: daftarProduk.isEmpty
                ? KeadaanKosong(
                    icon: Icons.inventory_2_outlined,
                    title: 'Produk tidak ditemukan',
                    message: 'Semua varian bisa diatur di menu Produk.',
                    actionLabel:
                        catalog.produkAktif.isEmpty && adalahAdmin
                        ? 'Lihat Produk'
                        : null,
                    onAction: catalog.produkAktif.isEmpty && adalahAdmin
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TampilanProduk(),
                            ),
                          )
                        : null,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width < 520
                          ? 2
                          : width < 760
                          ? 3
                          : width < 1050
                          ? 4
                          : 5;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: crossAxisCount == 2 ? 0.95 : 0.88,
                        ),
                        itemCount: daftarProduk.length,
                        itemBuilder: (context, index) {
                          final produk = daftarProduk[index];
                          return KartuProduk(
                            produk: produk,
                            onTap: () {
                              if (produk.nama.toLowerCase().contains(
                                'pisang',
                              )) {
                                tampilkanLembarTambahan(context, produk);
                                return;
                              }
                              final galat = context.read<PenyediaKeranjang>().tambah(
                                produk,
                              );
                              if (galat != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(galat)));
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${produk.nama} ditambahkan'),
                                  duration: const Duration(milliseconds: 900),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: keranjang.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WarnaAplikasi.ink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${keranjang.totalJumlah} item · ${Uang.format(keranjang.total)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Tap untuk lihat keranjang & bayar',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: WarnaAplikasi.primary,
                      minimumSize: const Size(92, 44),
                    ),
                    onPressed: _bukaKeranjang,
                    child: const Text('BAYAR'),
                  ),
                ],
              ),
            ),
    );
  }
}








