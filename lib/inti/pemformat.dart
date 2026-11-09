import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Format Rupiah dengan pemisah ribuan: Rp20.000
class Uang {
  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  static String format(num value, {bool withSymbol = true}) {
    final rounded = value.round();
    final sign = rounded < 0 ? '-' : '';
    final digits = _decimal.format(rounded.abs());
    return withSymbol ? '${sign}Rp$digits' : '$sign$digits';
  }

  static String polos(num value) => format(value, withSymbol: false);

  /// Membaca teks nominal yang sudah berformat (titik ribuan).
  static double urai(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return double.tryParse(digits) ?? 0;
  }
}

class Tanggal {
  static String tanggal(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

  static String waktu(DateTime value) => DateFormat('HH:mm').format(value);

  static String lengkap(DateTime value) =>
      DateFormat('dd/MM/yyyy HH:mm').format(value);

  static String bulanTahun(DateTime value) =>
      DateFormat('MMMM yyyy', 'id_ID').format(value);

  static String singkatHari(DateTime value) =>
      DateFormat('EEE', 'id_ID').format(value);

  static String nomorHari(DateTime value) => DateFormat('d').format(value);

  static String capStruk(DateTime value) =>
      DateFormat('yyyyMMdd').format(value);
}

/// Input nominal otomatis memberi titik ribuan saat diketik.
class PemformatRibuan extends TextInputFormatter {
  final NumberFormat _format = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    if (digits.length > 12) return oldValue;
    final parsed = int.tryParse(digits);
    if (parsed == null) return oldValue;
    final formatted = _format.format(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
