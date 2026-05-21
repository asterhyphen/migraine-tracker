/// Constant label for "Other" causes.
const String otherCauseLabel = 'Other';

/// Default intensity level for new entries.
const double defaultIntensity = 5.0;

/// Display list of causes, combining default and selected causes.
List<String> displayCauses(List<String> causes, Set<String> selectedCauses) {
  final ordered = <String>[...causes];
  for (final selected in selectedCauses) {
    if (!ordered.contains(selected)) {
      ordered.add(selected);
    }
  }
  return ordered;
}

/// Check if a cause string represents a saved "Other" cause.
bool isSavedOtherCause(String cause) {
  final trimmed = cause.trim();
  return trimmed == otherCauseLabel ||
      trimmed.toLowerCase().startsWith('${otherCauseLabel.toLowerCase()}:');
}

/// Extract the detail text from a saved "Other" cause.
/// Returns empty string if no detail is found.
String extractOtherCauseDetail(String cause) {
  final trimmed = cause.trim();
  if (trimmed == otherCauseLabel) return '';
  final colonIndex = trimmed.indexOf(':');
  if (colonIndex == -1) return '';
  return trimmed.substring(colonIndex + 1).trim();
}

/// Build list of causes for saving, handling "Other" causes specially.
List<String> buildCausesForSave(
  Set<String> selectedCauses,
  String otherCauseDetail,
) {
  final causes = <String>[];
  for (final cause in selectedCauses) {
    final trimmed = cause.trim();
    if (trimmed.isEmpty || trimmed == otherCauseLabel) continue;
    causes.add(trimmed);
  }

  if (selectedCauses.contains(otherCauseLabel)) {
    final sanitized = sanitizeOtherCauseDetail(otherCauseDetail);
    causes.add(
      sanitized.isEmpty ? otherCauseLabel : '$otherCauseLabel: $sanitized',
    );
  }

  return causes;
}

/// Sanitize "Other" cause detail text.
/// Removes extra whitespace and commas.
String sanitizeOtherCauseDetail(String value) {
  return value.trim().replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ');
}

/// Check if there are unsaved changes to the entry.
bool hasUnsavedChanges({
  required bool initialHadMigraine,
  required bool currentHadMigraine,
  required int initialIntensity,
  required int currentIntensity,
  required bool initialTookPainkillers,
  required bool currentTookPainkillers,
  required String initialNotes,
  required String currentNotes,
  required Set<String> initialCauses,
  required Set<String> currentCauses,
  required DateTime initialEntryDate,
  required DateTime currentEntryDate,
  required bool isEditingExistingEntry,
}) {
  if (currentHadMigraine != initialHadMigraine) return true;
  if (currentIntensity != initialIntensity) return true;
  if (currentTookPainkillers != initialTookPainkillers) return true;
  if (currentNotes.trim() != initialNotes.trim()) return true;
  if (!currentCauses.containsAll(initialCauses) ||
      !initialCauses.containsAll(currentCauses)) {
    return true;
  }
  // Only check date changes for new entries
  if (!isEditingExistingEntry) {
    final normalizedInitialDate = DateTime(
      initialEntryDate.year,
      initialEntryDate.month,
      initialEntryDate.day,
    );
    final normalizedCurrentDate = DateTime(
      currentEntryDate.year,
      currentEntryDate.month,
      currentEntryDate.day,
    );
    if (normalizedCurrentDate != normalizedInitialDate) {
      return true;
    }
  }
  return false;
}
