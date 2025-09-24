import 'package:flutter_test/flutter_test.dart';
import 'package:cruci_verba/providers/game_provider.dart';
import 'package:cruci_verba/models/difficulty_level.dart';

void main() {
  group('GameProvider Difficulty Tests', () {
    late GameProvider gameProvider;

    setUp(() {
      gameProvider = GameProvider();
    });

    tearDown(() {
      gameProvider.dispose();
    });

    test('GameProvider should have default medium difficulty', () {
      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.medium));
    });

    test('newGameWithDifficulty should update current difficulty', () async {
      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.medium));

      // This will fail to generate a puzzle due to missing database,
      // but we can test that the difficulty is set
      try {
        await gameProvider.newGameWithDifficulty(DifficultyLevel.hard);
      } catch (e) {
        // Expected to fail without proper database setup
      }

      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.hard));
    });

    test('newGameWithDifficulty should set loading state correctly', () async {
      expect(gameProvider.isLoading, isFalse);

      // Start a game generation (will fail but we can test loading state)
      final gameFuture = gameProvider.newGameWithDifficulty(DifficultyLevel.easy);

      // Should be loading immediately after call
      expect(gameProvider.isLoading, isTrue);

      // Wait for completion (will fail)
      try {
        await gameFuture;
      } catch (e) {
        // Expected to fail without proper database setup
      }

      // Should not be loading after completion
      expect(gameProvider.isLoading, isFalse);
    });

    test('newGameWithDifficulty should handle different difficulty levels', () async {
      final difficulties = [
        DifficultyLevel.easy,
        DifficultyLevel.medium,
        DifficultyLevel.hard,
      ];

      for (final difficulty in difficulties) {
        try {
          await gameProvider.newGameWithDifficulty(difficulty);
        } catch (e) {
          // Expected to fail without proper database setup
        }

        expect(gameProvider.currentDifficulty, equals(difficulty));
      }
    });

    test('newGame should use current difficulty by default', () async {
      // Set difficulty to hard
      try {
        await gameProvider.newGameWithDifficulty(DifficultyLevel.hard);
      } catch (e) {
        // Expected to fail
      }

      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.hard));

      // Call newGame without specifying difficulty
      try {
        await gameProvider.newGame();
      } catch (e) {
        // Expected to fail
      }

      // Should still be hard difficulty
      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.hard));
    });

    test('newGameWithDifficulty should clear error message', () async {
      // Simulate an error state
      try {
        await gameProvider.newGameWithDifficulty(DifficultyLevel.easy);
      } catch (e) {
        // Will set error message
      }

      // Error message should be set
      expect(gameProvider.errorMessage, isNotNull);

      // Start new game
      final gameFuture = gameProvider.newGameWithDifficulty(DifficultyLevel.medium);

      // Error message should be cleared immediately
      expect(gameProvider.errorMessage, isNull);

      try {
        await gameFuture;
      } catch (e) {
        // Expected to fail
      }
    });

    test('newGameWithDifficulty should stop timer before starting new game', () async {
      // Start timer manually
      gameProvider.startTimer();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 100));

      // Timer should be running
      expect(gameProvider.gameState.elapsedTime.inMilliseconds, greaterThan(0));

      // Start new game
      try {
        await gameProvider.newGameWithDifficulty(DifficultyLevel.easy);
      } catch (e) {
        // Expected to fail
      }

      // Timer should be reset (new game state)
      expect(gameProvider.gameState.elapsedTime, equals(Duration.zero));
    });

    test('newGameWithDifficulty with custom grid size should work', () async {
      try {
        await gameProvider.newGameWithDifficulty(
          DifficultyLevel.hard,
          rows: 20,
          cols: 20,
        );
      } catch (e) {
        // Expected to fail without proper database setup
      }

      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.hard));
    });

    test('GameProvider should maintain state across multiple difficulty changes', () async {
      final testSequence = [
        DifficultyLevel.easy,
        DifficultyLevel.hard,
        DifficultyLevel.medium,
        DifficultyLevel.easy,
      ];

      for (final difficulty in testSequence) {
        try {
          await gameProvider.newGameWithDifficulty(difficulty);
        } catch (e) {
          // Expected to fail
        }

        expect(gameProvider.currentDifficulty, equals(difficulty));
        expect(gameProvider.isLoading, isFalse); // Should finish loading
      }
    });
  });

  group('GameProvider Difficulty Integration Tests', () {
    late GameProvider gameProvider;

    setUp(() {
      gameProvider = GameProvider();
    });

    tearDown(() {
      gameProvider.dispose();
    });

    test('GameProvider should handle rapid difficulty changes', () async {
      final futures = <Future>[];

      // Start multiple difficulty changes rapidly
      futures.add(gameProvider.newGameWithDifficulty(DifficultyLevel.easy));
      futures.add(gameProvider.newGameWithDifficulty(DifficultyLevel.hard));
      futures.add(gameProvider.newGameWithDifficulty(DifficultyLevel.medium));

      // Wait for all to complete (they will fail but that's expected)
      try {
        await Future.wait(futures);
      } catch (e) {
        // Expected to fail
      }

      // Should end up with the last difficulty set
      expect(gameProvider.currentDifficulty, equals(DifficultyLevel.medium));
      expect(gameProvider.isLoading, isFalse);
    });

    test('GameProvider should notify listeners on difficulty changes', () async {
      bool notified = false;
      gameProvider.addListener(() {
        notified = true;
      });

      try {
        await gameProvider.newGameWithDifficulty(DifficultyLevel.hard);
      } catch (e) {
        // Expected to fail
      }

      expect(notified, isTrue);
    });
  });
}