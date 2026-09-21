import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_questions.dart';
import 'package:nearsoul/utils/quiz_scoring.dart';

void main() {
  resultLogicTests();
  group('scoring (3 multiple-choice questions, match when >= 2 agree)', () {
    test('counts identical answers', () {
      expect(countMatchingAnswers([0, 1, 0], [0, 1, 0]), 3);
      expect(countMatchingAnswers([0, 1, 0], [0, 0, 1]), 1);
      expect(countMatchingAnswers([1, 1, 1], [0, 0, 0]), 0);
    });

    test('threshold is 2 of 3', () {
      expect(kMatchThreshold, 2);
      expect(isQuizMatch(3), isTrue);
      expect(isQuizMatch(2), isTrue);
      expect(isQuizMatch(1), isFalse);
      expect(isQuizMatch(0), isFalse);
    });

    test('an unanswered question (-1) never counts, even if both left it empty', () {
      expect(countMatchingAnswers([-1, -1, -1], [-1, -1, -1]), 0);
      expect(countMatchingAnswers([0, -1, 1], [0, -1, 1]), 2);
    });

    test('free text needs at least 20 characters after trimming', () {
      expect(isFreeTextValid(''), isFalse);
      expect(isFreeTextValid('haha'), isFalse);
      expect(isFreeTextValid('a' * 19), isFalse);
      expect(isFreeTextValid('a' * 20), isTrue);
      expect(isFreeTextValid('   ${'a' * 19}   '), isFalse); // khoảng trắng không được tính
    });
  });

  group('question bank', () {
    test('has a bank of 15-20+ questions', () {
      expect(kMultipleChoiceBank.length + kFreeTextBank.length, inInclusiveRange(15, 30));
      expect(kMultipleChoiceBank.length, greaterThanOrEqualTo(10));
      expect(kFreeTextBank.length, greaterThanOrEqualTo(6));
    });

    test('every multiple-choice question has exactly 2 options, free text has none', () {
      for (final q in kMultipleChoiceBank) {
        expect(q.type, QuestionType.multipleChoice);
        expect(q.options, hasLength(2), reason: q.id);
        expect(q.options!.toSet(), hasLength(2), reason: '${q.id} có hai đáp án giống nhau');
      }
      for (final q in kFreeTextBank) {
        expect(q.type, QuestionType.freeText);
        expect(q.options, isNull, reason: q.id);
      }
    });

    test('question ids are unique', () {
      final ids = [...kMultipleChoiceBank, ...kFreeTextBank].map((q) => q.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('a quiz is 3 multiple-choice questions followed by 2 free-text questions, without repeats', () {
      for (var seed = 0; seed < 25; seed++) {
        final quiz = pickQuizQuestions(random: Random(seed));
        expect(quiz, hasLength(5));
        expect(quiz.take(3).every((q) => q.type == QuestionType.multipleChoice), isTrue, reason: 'seed $seed');
        expect(quiz.skip(3).every((q) => q.type == QuestionType.freeText), isTrue, reason: 'seed $seed');
        expect(quiz.map((q) => q.id).toSet(), hasLength(5), reason: 'seed $seed');
      }
    });

    test('the same seed gives both people the same quiz; different seeds vary', () {
      final a = pickQuizQuestions(random: Random(7)).map((q) => q.id).toList();
      final b = pickQuizQuestions(random: Random(7)).map((q) => q.id).toList();
      expect(a, b);

      final variety = {for (var s = 0; s < 20; s++) pickQuizQuestions(random: Random(s)).map((q) => q.id).join(',')};
      expect(variety.length, greaterThan(5));
    });
  });
}

void resultLogicTests() {
  group('result screen logic', () {
    test('match percent follows the number of agreeing multiple-choice answers', () {
      expect(matchPercent(0), 0);
      expect(matchPercent(1), 33);
      expect(matchPercent(2), 67);
      expect(matchPercent(3), 100);
      expect(matchPercent(5, total: 0), 0);
      expect(matchPercent(9), 100); // không vượt quá 100
    });
  });
}
