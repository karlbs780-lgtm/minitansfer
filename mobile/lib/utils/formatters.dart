import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Formats an integer FCFA amount with space thousands separators, e.g. `10 000`.
String formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}

/// `10 000 FCFA`
String formatFcfa(int amount) => '${formatAmount(amount)} ${AppConfig.currency}';

final DateFormat _dateFormat = DateFormat('dd/MM/yyyy • HH:mm');
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

String formatDateTime(DateTime dateTime) => _dateFormat.format(dateTime);

String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

/// Relative day label used as a section header in the history list.
String dayLabel(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Hier';
  return _dayFormat.format(dateTime);
}
