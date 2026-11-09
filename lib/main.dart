import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'inti/tema_aplikasi.dart';
import 'data/basis_data.dart';
import 'penyedia/penyedia_auth.dart';
import 'penyedia/penyedia_keranjang.dart';
import 'penyedia/penyedia_catatan_kas.dart';
import 'penyedia/penyedia_katalog.dart';
import 'penyedia/penyedia_tambahan.dart';
import 'penyedia/penyedia_pengaturan.dart';
import 'penyedia/pengendali_shell.dart';
import 'penyedia/penyedia_transaksi.dart';
import 'tampilan/tampilan_masuk.dart';
import 'tampilan/tampilan_utama.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BasisData.siapkan();
  await initializeDateFormatting('id_ID');
  runApp(const AplikasiSinarKasir());
}

class AplikasiSinarKasir extends StatelessWidget {
  const AplikasiSinarKasir({super.key});

  @override
  Widget build(BuildContext context) {
    final db = BasisData.instance;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PenyediaAuth(db)),
        ChangeNotifierProvider(create: (_) => PengendaliShell()),
        ChangeNotifierProvider(
          create: (_) => PenyediaTambahan(BasisData.instance)..load(),
        ),
        ChangeNotifierProvider(create: (_) => PenyediaPengaturan()..load()),
        ChangeNotifierProvider(create: (_) => PenyediaKatalog(db)..load()),
        ChangeNotifierProvider(create: (_) => PenyediaKeranjang()),
        ChangeNotifierProvider(
          create: (_) => PenyediaTransaksi(db)..muatTerbaru(),
        ),
        ChangeNotifierProvider(create: (_) => PenyediaCatatanKas(db)..load()),
      ],
      child: MaterialApp(
        title: 'Sinar Kasir',
        debugShowCheckedModeBanner: false,
        theme: TemaAplikasi.light(),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer<PenyediaAuth>(
          builder: (context, auth, _) =>
              auth.sudahMasuk ? const TampilanUtama() : const TampilanMasuk(),
        ),
      ),
    );
  }
}
