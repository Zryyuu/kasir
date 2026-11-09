import 'package:flutter/material.dart';

import '../inti/tema_aplikasi.dart';
import '../inti/pemformat.dart';
import '../model/produk.dart';

class KartuProduk extends StatelessWidget {
  const KartuProduk({super.key, required this.produk, this.onTap});

  final Produk produk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = produk.stokHabis;
    final lowStock = produk.stokRendah;

    final warnaLabel = outOfStock
        ? WarnaAplikasi.danger
        : lowStock
        ? WarnaAplikasi.warning
        : WarnaAplikasi.muted;
    final latarLabel = outOfStock
        ? WarnaAplikasi.dangerSoft
        : lowStock
        ? WarnaAplikasi.warningSoft
        : const Color(0xFFF1F5F9);

    return Opacity(
      opacity: outOfStock ? 0.62 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: outOfStock ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WarnaAplikasi.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WarnaAplikasi.cream,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: WarnaAplikasi.primaryDark,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: latarLabel,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        outOfStock ? 'HABIS' : 'Stok ${produk.stok}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: warnaLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    produk.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: WarnaAplikasi.ink,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Uang.format(produk.harga),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: WarnaAplikasi.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lowStock ? 'Stok menipis' : 'Sisa ${produk.stok} porsi',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: lowStock ? WarnaAplikasi.warning : WarnaAplikasi.muted,
                    fontWeight: lowStock ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
