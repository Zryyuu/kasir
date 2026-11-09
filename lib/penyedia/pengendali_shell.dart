import 'package:flutter/foundation.dart';

/// Mengatur tab yang aktif pada bottom navigation dan tab Keuangan.
class PengendaliShell extends ChangeNotifier {
  int _index = 0;
  int _financeTab = 0;

  int get index => _index;

  /// 0 = Pengeluaran, 1 = Pemasukan
  int get tabKeuangan => _financeTab;

  void go(int index) {
    if (index < 0 || index > 4 || _index == index) return;
    _index = index;
    notifyListeners();
  }

  void pergiKeuangan(int tab) {
    final changed = _index != 4 || _financeTab != tab;
    _index = 4;
    _financeTab = tab;
    if (changed) notifyListeners();
  }

  void aturTabKeuangan(int tab) {
    if (tab < 0 || tab > 1 || _financeTab == tab) return;
    _financeTab = tab;
    notifyListeners();
  }

  /// Kembalikan ke tab awal saat pengguna keluar.
  void reset() {
    final berubah = _index != 0 || _financeTab != 0;
    _index = 0;
    _financeTab = 0;
    if (berubah) notifyListeners();
  }
}
