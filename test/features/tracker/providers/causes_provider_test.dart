import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migraine_tracker/features/tracker/data/cause_options_repository.dart';
import 'package:migraine_tracker/features/tracker/models/cause_option.dart';
import 'package:migraine_tracker/features/tracker/providers/causes_provider.dart';
import 'package:migraine_tracker/features/tracker/pages/_utils/log_utils.dart' as log_utils;

class FakeCauseOptionsRepository implements CauseOptionsRepository {
  List<String> _causes = List<String>.from(defaultCauseOptions);

  @override
  Future<List<String>> loadCauses() async => List<String>.from(_causes);

  @override
  Future<void> saveCauses(List<String> causes) async {
    _causes = List<String>.from(causes);
  }
}

void main() {
  group('CauseOptionsController', () {
    late FakeCauseOptionsRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeCauseOptionsRepository();
      container = ProviderContainer(
        overrides: [
          causeOptionsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loads initial default cause options', () async {
      final causes = await container.read(causeOptionsProvider.future);
      expect(causes, defaultCauseOptions);
    });

    test('addCause inserts before "Other" and persists', () async {
      await container.read(causeOptionsProvider.future);
      final notifier = container.read(causeOptionsProvider.notifier);

      final added = await notifier.addCause('Caffeine');
      expect(added, isTrue);

      final updated = container.read(causeOptionsProvider).value!;
      expect(updated.contains('Caffeine'), isTrue);
      expect(updated.last, 'Other');
      expect(updated[updated.length - 2], 'Caffeine');

      final saved = await fakeRepo.loadCauses();
      expect(saved.contains('Caffeine'), isTrue);
    });

    test('addCause rejects case-insensitive duplicates', () async {
      await container.read(causeOptionsProvider.future);
      final notifier = container.read(causeOptionsProvider.notifier);

      final added = await notifier.addCause('stress');
      expect(added, isFalse);

      final updated = container.read(causeOptionsProvider).value!;
      expect(
        updated.where((c) => c.toLowerCase() == 'stress').length,
        equals(1),
      );
    });

    test('addCause rejects empty string', () async {
      await container.read(causeOptionsProvider.future);
      final notifier = container.read(causeOptionsProvider.notifier);

      final added = await notifier.addCause('   ');
      expect(added, isFalse);
    });

    test('removeCause removes specified cause', () async {
      await container.read(causeOptionsProvider.future);
      final notifier = container.read(causeOptionsProvider.notifier);

      await notifier.removeCause('Smoke');
      final updated = container.read(causeOptionsProvider).value!;
      expect(updated.contains('Smoke'), isFalse);
    });
  });

  group('displayCauses helper', () {
    test('inserts custom cause before "Other"', () {
      final base = ['Stress', 'Food', 'Other'];
      final selected = {'Stress', 'Bright Lights'};

      final result = log_utils.displayCauses(base, selected);
      expect(result.contains('Bright Lights'), isTrue);
      expect(result.last, 'Other');
      expect(result[result.length - 2], 'Bright Lights');
    });
  });
}
