import 'package:flutter_test/flutter_test.dart';
import 'package:cruci_verba/models/difficulty_level.dart';

void main() {
  group('DifficultyLevel Tests', () {
    test('DifficultyLevel enum should have correct display names', () {
      expect(DifficultyLevel.easy.displayName, equals('Kolay'));
      expect(DifficultyLevel.medium.displayName, equals('Orta'));
      expect(DifficultyLevel.hard.displayName, equals('Zor'));
    });

    test('DifficultyLevel enum should have correct descriptions', () {
      expect(DifficultyLevel.easy.description, equals('Kolay kelimeler, az sayıda kelime'));
      expect(DifficultyLevel.medium.description, equals('Orta seviye kelimeler'));
      expect(DifficultyLevel.hard.description, equals('Zor kelimeler, çok sayıda kelime'));
    });

    test('DifficultyLevel enum should have correct maxWords', () {
      expect(DifficultyLevel.easy.maxWords, equals(15));
      expect(DifficultyLevel.medium.maxWords, equals(35));
      expect(DifficultyLevel.hard.maxWords, equals(60));
    });

    test('DifficultyLevel enum should have correct gridSize', () {
      expect(DifficultyLevel.easy.gridSize, equals(12));
      expect(DifficultyLevel.medium.gridSize, equals(18));
      expect(DifficultyLevel.hard.gridSize, equals(25));
    });

    test('DifficultyLevel enum should have correct word length constraints', () {
      // Easy level
      expect(DifficultyLevel.easy.minWordLength, equals(3));
      expect(DifficultyLevel.easy.maxWordLength, equals(8));

      // Medium level
      expect(DifficultyLevel.medium.minWordLength, equals(3));
      expect(DifficultyLevel.medium.maxWordLength, equals(12));

      // Hard level
      expect(DifficultyLevel.hard.minWordLength, equals(4));
      expect(DifficultyLevel.hard.maxWordLength, equals(15));
    });
  });

  group('DifficultySettings Tests', () {
    test('DifficultySettings.fromLevel should create correct settings for easy', () {
      final settings = DifficultySettings.fromLevel(DifficultyLevel.easy);

      expect(settings.level, equals(DifficultyLevel.easy));
      expect(settings.maxWords, equals(15));
      expect(settings.minWordLength, equals(3));
      expect(settings.maxWordLength, equals(8));
      expect(settings.gridSize, equals(12));
      expect(settings.similarityThreshold, equals(0.7));
    });

    test('DifficultySettings.fromLevel should create correct settings for medium', () {
      final settings = DifficultySettings.fromLevel(DifficultyLevel.medium);

      expect(settings.level, equals(DifficultyLevel.medium));
      expect(settings.maxWords, equals(35));
      expect(settings.minWordLength, equals(3));
      expect(settings.maxWordLength, equals(12));
      expect(settings.gridSize, equals(18));
      expect(settings.similarityThreshold, equals(0.5));
    });

    test('DifficultySettings.fromLevel should create correct settings for hard', () {
      final settings = DifficultySettings.fromLevel(DifficultyLevel.hard);

      expect(settings.level, equals(DifficultyLevel.hard));
      expect(settings.maxWords, equals(60));
      expect(settings.minWordLength, equals(4));
      expect(settings.maxWordLength, equals(15));
      expect(settings.gridSize, equals(25));
      expect(settings.similarityThreshold, equals(0.3));
    });

    test('DifficultySettings should maintain consistency across difficulty levels', () {
      final easy = DifficultySettings.fromLevel(DifficultyLevel.easy);
      final medium = DifficultySettings.fromLevel(DifficultyLevel.medium);
      final hard = DifficultySettings.fromLevel(DifficultyLevel.hard);

      // Easy should have fewer words than medium, medium fewer than hard
      expect(easy.maxWords < medium.maxWords, isTrue);
      expect(medium.maxWords < hard.maxWords, isTrue);

      // Easy should have higher similarity threshold (easier clues)
      expect(easy.similarityThreshold > medium.similarityThreshold, isTrue);
      expect(medium.similarityThreshold > hard.similarityThreshold, isTrue);

      // Hard should allow longer words
      expect(hard.maxWordLength >= medium.maxWordLength, isTrue);
      expect(medium.maxWordLength >= easy.maxWordLength, isTrue);
    });

    test('DifficultySettings constructor should work correctly', () {
      const customSettings = DifficultySettings(
        level: DifficultyLevel.medium,
        maxWords: 25,
        minWordLength: 4,
        maxWordLength: 10,
        gridSize: 16,
        similarityThreshold: 0.6,
      );

      expect(customSettings.level, equals(DifficultyLevel.medium));
      expect(customSettings.maxWords, equals(25));
      expect(customSettings.minWordLength, equals(4));
      expect(customSettings.maxWordLength, equals(10));
      expect(customSettings.gridSize, equals(16));
      expect(customSettings.similarityThreshold, equals(0.6));
    });
  });
}