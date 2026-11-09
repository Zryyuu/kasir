import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../penyedia/penyedia_auth.dart';
import 'tampilan_beranda.dart';
import 'tampilan_kasir.dart';

class TampilanUtama extends StatelessWidget {
  const TampilanUtama({super.key});

  @override
  Widget build(BuildContext context) {
    final adalahAdmin = context.watch<PenyediaAuth>().adalahAdmin;
    if (!adalahAdmin) return const TampilanKasir();
    return const TampilanBeranda();
  }
}
