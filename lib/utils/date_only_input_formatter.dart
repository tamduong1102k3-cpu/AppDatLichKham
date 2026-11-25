import 'package:flutter/services.dart';


class DateOnlyInputFormatter extends TextInputFormatter {

  static const int _maxDigits = 8;

  static String format(String raw) {

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;


    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 1 || i == 3) {
        buffer.write('/');
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = format(newValue.text);


    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
