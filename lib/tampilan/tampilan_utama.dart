import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../penyedia/penyedia_auth.dart';
import '../penyedia/pengendali_shell.dart';
import 'tampilan_keuangan.dart';
import 'tampilan_riwayat.dart';
import 'tampilan_beranda.dart';
import 'tampilan_kasir.dart';
import 'tampilan_laporan.dart';

class TampilanUtama extends StatelessWidget {
  const TampilanUtama({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<PengendaliShell>();
    final adalahAdmin = context.watch<PenyediaAuth>().adalahAdmin;
    final index = adalahAdmin ? shell.index : (shell.index == 0 ? 0 : 1);

    final children = adalahAdmin
        ? const [
            TampilanBeranda(),
            TampilanKasir(),
            TampilanRiwayat(),
            TampilanLaporan(),
            TampilanKeuangan(),
          ]
        : const [TampilanBeranda(), TampilanKasir()];

    final destinations = adalahAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded),
              label: 'Kasir',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Keuangan',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded),
              label: 'Kasir',
            ),
          ];

    return Scaffold(
      body: IndexedStack(index: index, children: children),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: adalahAdmin ? shell.go : (i) => shell.go(i),
        destinations: destinations,
      ),
    );
  }
}
