import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/audio/queue_differ.dart';

void main() {
  group('QueueDiffer Tests', () {
    test('diff on empty lists returns empty edits', () {
      final edits = QueueDiffer.diff([], []);
      expect(edits, isEmpty);
      expect(QueueDiffer.validate([], [], edits), isTrue);
    });

    test('diff on identical lists returns empty edits', () {
      final current = ['u:track1#0', 'u:track2#0', 'u:track3#0'];
      final target = ['u:track1#0', 'u:track2#0', 'u:track3#0'];

      final edits = QueueDiffer.diff(current, target);
      expect(edits, isEmpty);
      expect(QueueDiffer.validate(current, target, edits), isTrue);
    });

    test('diff detects single reorder move with minimal edits', () {
      final current = ['u:a#0', 'u:b#0', 'u:c#0', 'u:d#0'];
      final target = ['u:a#0', 'u:c#0', 'u:b#0', 'u:d#0'];

      final edits = QueueDiffer.diff(current, target);
      expect(edits.length, equals(1));
      expect(edits.first, isA<QueueEditMove>());
      expect(QueueDiffer.validate(current, target, edits), isTrue);
      expect(QueueDiffer.applyEdits(current, target, edits), equals(target));
    });

    test('diff detects removals correctly', () {
      final current = ['u:a#0', 'u:b#0', 'u:c#0'];
      final target = ['u:a#0', 'u:c#0'];

      final edits = QueueDiffer.diff(current, target);
      expect(edits, contains(isA<QueueEditRemove>()));
      expect(QueueDiffer.validate(current, target, edits), isTrue);
      expect(QueueDiffer.applyEdits(current, target, edits), equals(target));
    });

    test('diff detects insertions and pagination appends correctly', () {
      final current = ['u:a#0', 'u:b#0'];
      final target = ['u:a#0', 'u:b#0', 'u:c#0', 'u:d#0'];

      final edits = QueueDiffer.diff(current, target);
      expect(edits.length, equals(2));
      expect(edits.every((e) => e is QueueEditInsert), isTrue);
      expect(QueueDiffer.validate(current, target, edits), isTrue);
      expect(QueueDiffer.applyEdits(current, target, edits), equals(target));
    });

    test('computeKeys handles duplicates and uids safely', () {
      final sources = [
        const KeySource(uri: 'uri1', uid: 'uid1'),
        const KeySource(uri: 'uri1', uid: 'uid1'),
        const KeySource(uri: 'uri2', uid: null),
        const KeySource(uri: 'uri2', uid: ''),
      ];

      final keys = QueueDiffer.computeKeys(sources);
      expect(keys, equals([
        'u:uid1#0',
        'u:uid1#1',
        'r:uri2#0',
        'r:uri2#1',
      ]));
    });

    test('complex permutations preserve target order and validation', () {
      final current = ['u:1#0', 'u:2#0', 'u:3#0', 'u:4#0', 'u:5#0'];
      final target = ['u:5#0', 'u:2#0', 'u:6#0', 'u:1#0', 'u:4#0'];

      final edits = QueueDiffer.diff(current, target);
      expect(QueueDiffer.validate(current, target, edits), isTrue);
      expect(QueueDiffer.applyEdits(current, target, edits), equals(target));
    });
  });
}
