import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PenyediaPengaturan extends ChangeNotifier {
  static const namaTokoDefault = 'Pisang Keju Sinar';
  static const namaKasirDefault = 'Sinar';
  static const double hargaMixVarianDefault = 18000;

  String _shopName = namaTokoDefault;
  String _cashierName = namaKasirDefault;
  double _hargaMixVarian = hargaMixVarianDefault;
  bool _loaded = false;

  String get namaToko => _shopName;
  String get namaKasir => _cashierName;
  double get hargaMixVarian => _hargaMixVarian;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _shopName = prefs.getString('shopName') ?? namaTokoDefault;
    _cashierName = prefs.getString('cashierName') ?? namaKasirDefault;
    _hargaMixVarian =
        prefs.getDouble('hargaMixVarian') ?? hargaMixVarianDefault;
    if (_shopName.trim().isEmpty) _shopName = namaTokoDefault;
    if (_cashierName.trim().isEmpty) _cashierName = namaKasirDefault;
    if (_hargaMixVarian <= 0) _hargaMixVarian = hargaMixVarianDefault;
    _loaded = true;
    notifyListeners();
  }

  Future<void> save({
    required String namaToko,
    required String namaKasir,
    double? hargaMixVarian,
  }) async {
    final cleanShop = namaToko.trim().isEmpty
        ? namaTokoDefault
        : namaToko.trim();
    final cleanCashier = namaKasir.trim().isEmpty
        ? namaKasirDefault
        : namaKasir.trim();
    final cleanMix = (hargaMixVarian ?? _hargaMixVarian) > 0
        ? (hargaMixVarian ?? _hargaMixVarian)
        : hargaMixVarianDefault;

    _shopName = cleanShop;
    _cashierName = cleanCashier;
    _hargaMixVarian = cleanMix;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', cleanShop);
    await prefs.setString('cashierName', cleanCashier);
    await prefs.setDouble('hargaMixVarian', cleanMix);
    notifyListeners();
  }
}
