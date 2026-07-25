import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) return oldValue;

    if (text.length < oldDigits.length) {
      return TextEditingValue(
        text: _formatDigits(text),
        selection: TextSelection.collapsed(
          offset: _formatDigits(text).length,
        ),
      );
    }

    final formatted = _formatDigits(text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatDigits(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('/');
      }
    }
    return buffer.toString();
  }
}
