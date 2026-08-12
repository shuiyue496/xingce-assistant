import 'package:flutter_test/flutter_test.dart';
import 'package:xingce_assistant/generators/calc_generator.dart';
import 'package:xingce_assistant/generators/data_generator.dart';
import 'package:xingce_assistant/generators/seq_generator.dart';

void main() {
  group('calc generator', () {
    for (final t in CalcGenerator.types) {
      test('${t.id} produces valid questions', () {
        final qs = CalcGenerator.generate(t.id, 50);
        expect(qs.length, 50);
        for (final q in qs) {
          expect(q.prompt, isNotEmpty);
          expect(q.answerText, isNotEmpty);
          expect(q.answerNum, isNotNull);
          // the generated answer must be accepted by the checker
          expect(q.check(q.answerText), isTrue,
              reason: '${t.id}: ${q.prompt} answer=${q.answerText}');
        }
      });
    }
  });

  group('data generator', () {
    for (final t in DataGenerator.types) {
      test('${t.id} produces valid questions', () {
        final qs = DataGenerator.generate(t.id, 50);
        expect(qs.length, 50);
        for (final q in qs) {
          expect(q.prompt, isNotEmpty);
          expect(q.answerText, isNotEmpty);
          expect(q.check(q.answerText), isTrue,
              reason: '${t.id}: ${q.prompt} answer=${q.answerText}');
        }
      });
    }
  });

  group('seq generator', () {
    for (final t in SeqGenerator.types) {
      test('${t.id} produces 4 unique options containing the answer', () {
        final qs = SeqGenerator.generate(t.id, 100);
        expect(qs.length, 100);
        for (final q in qs) {
          expect(q.options, isNotNull);
          expect(q.options!.length, 4);
          expect(q.options!.toSet().length, 4, reason: '${t.id}: options not unique: ${q.options}');
          expect(q.options, contains(q.answerText),
              reason: '${t.id}: ${q.prompt} answer=${q.answerText} opts=${q.options}');
          expect(q.check(q.answerText), isTrue);
        }
      });
    }
  });
}
