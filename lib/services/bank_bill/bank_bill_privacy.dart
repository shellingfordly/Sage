import 'alipay_csv_parser.dart';

/// Masks sensitive fields in bill import source lines for UI display only.
String redactBankBillSourceLine(String sourceLine) {
  if (sourceLine.trim().isEmpty) {
    return sourceLine;
  }

  if (sourceLine.contains(',') &&
      RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(sourceLine)) {
    final fields = parseAlipayCsvLine(sourceLine);
    if (fields.length >= 4) {
      if (fields[3].trim().isNotEmpty && fields[3].trim() != '/') {
        fields[3] = '***';
      }
      for (final index in [9, 10]) {
        if (fields.length > index) {
          final value = fields[index].trim();
          if (value.isNotEmpty && value != '/') {
            fields[index] = '***';
          }
        }
      }
      return fields.join(',');
    }
  }

  var result = sourceLine.replaceAllMapped(
    RegExp(r'\d{11,}'),
    (match) {
      final digits = match.group(0)!;
      return '***${digits.substring(digits.length - 4)}';
    },
  );
  result = result.replaceAllMapped(
    RegExp(r'[\w.%+-]+@[\w.-]+\.\w+'),
    (_) => '***@***',
  );

  const maxLength = 120;
  if (result.length > maxLength) {
    return '${result.substring(0, maxLength)}…';
  }
  return result;
}
