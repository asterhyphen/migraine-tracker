import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';

/// Calculate the age from a date of birth.
int calculateAge(DateTime dob) {
  DateTime today = DateTime.now();
  int age = today.year - dob.year;

  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age;
}

/// Calculate the number of days since a given date.
/// Returns 0 if the date is null.
int daysSince(DateTime? date) {
  if (date == null) return 0;
  final now = DateTime.now();
  final delta = now.difference(DateTime(date.year, date.month, date.day));
  return delta.inDays;
}

/// Find the migraine entry for a specific date.
/// Returns null if no entry is found for that date.
MigraineEntry? entryForDate(List<MigraineEntry> entries, DateTime date) {
  final target = DateTime(date.year, date.month, date.day);
  for (final entry in entries) {
    final entryDate = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    if (entryDate == target) return entry;
  }
  return null;
}

/// Check if today is the birthday.
bool isBirthdayToday(DateTime dob) {
  final now = DateTime.now();
  return now.month == dob.month && now.day == dob.day;
}

/// Format date as DD/MM/YYYY.
String formatDate(DateTime date) {
  return formatDdMmYyyy(date);
}
