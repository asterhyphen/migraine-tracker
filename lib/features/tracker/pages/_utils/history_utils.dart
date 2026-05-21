import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';

Map<String, List<MigraineEntry>> groupByMonth(List<MigraineEntry> entries) {
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final map = <String, List<MigraineEntry>>{};
  for (final entry in entries) {
    final key = '${monthNames[entry.date.month - 1]} ${entry.date.year}';
    map.putIfAbsent(key, () => []).add(entry);
  }

  // Sort keys by year desc, month desc
  final sortedKeys = map.keys.toList()
    ..sort((a, b) {
      final aParts = a.split(' ');
      final bParts = b.split(' ');
      final aYear = int.parse(aParts[1]);
      final bYear = int.parse(bParts[1]);
      if (aYear != bYear) return bYear.compareTo(aYear);
      final aMonth = monthNames.indexOf(aParts[0]);
      final bMonth = monthNames.indexOf(bParts[0]);
      return bMonth.compareTo(aMonth);
    });

  final sortedMap = <String, List<MigraineEntry>>{};
  for (final key in sortedKeys) {
    sortedMap[key] = map[key]!;
  }
  return sortedMap;
}

List<MigraineEntry> filterEntries(List<MigraineEntry> entries, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return entries;

  return entries.where((entry) {
    final haystack = [
      formatDdMmYyyy(entry.date),
      formatDay(entry.date),
      entry.intensity.toString(),
      entry.painkillers ? 'painkillers' : 'no painkillers',
      entry.notes,
      ...entry.causes,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }).toList();
}
