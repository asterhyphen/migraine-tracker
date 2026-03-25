const _weekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String formatDdMmYyyy(DateTime date) {
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm/${date.year}';
}

String formatDayAndDate(DateTime date) {
  final day = _weekdayNames[date.weekday - 1];
  return '$day, ${formatDdMmYyyy(date)}';
}

DateTime? parseFlexibleDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final slashParts = text.split('/');
  if (slashParts.length == 3) {
    final day = int.tryParse(slashParts[0]);
    final month = int.tryParse(slashParts[1]);
    final year = int.tryParse(slashParts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return DateTime.tryParse(text);
}
