enum DifficultyLevel {
  easy,
  medium,
  hard,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Kolay';
      case DifficultyLevel.medium:
        return 'Orta';
      case DifficultyLevel.hard:
        return 'Zor';
    }
  }

  String get description {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Kolay kelimeler, az sayıda kelime';
      case DifficultyLevel.medium:
        return 'Orta seviye kelimeler';
      case DifficultyLevel.hard:
        return 'Zor kelimeler, çok sayıda kelime';
    }
  }

  int get maxWords {
    switch (this) {
      case DifficultyLevel.easy:
        return 15; // Fewer words for easy puzzles
      case DifficultyLevel.medium:
        return 35; // Medium amount of words
      case DifficultyLevel.hard:
        return 60; // More words for hard puzzles
    }
  }

  int get gridSize {
    switch (this) {
      case DifficultyLevel.easy:
        return 12; // Smaller grid for easy
      case DifficultyLevel.medium:
        return 18; // Medium grid size
      case DifficultyLevel.hard:
        return 25; // Larger grid for hard
    }
  }

  int get minWordLength {
    switch (this) {
      case DifficultyLevel.easy:
        return 3; // Shorter words for easy
      case DifficultyLevel.medium:
        return 3; // Standard minimum
      case DifficultyLevel.hard:
        return 4; // Longer words for hard
    }
  }

  int get maxWordLength {
    switch (this) {
      case DifficultyLevel.easy:
        return 8; // Shorter words for easy
      case DifficultyLevel.medium:
        return 12; // Medium length words
      case DifficultyLevel.hard:
        return 15; // Longer words for hard
    }
  }
}

class DifficultySettings {
  final DifficultyLevel level;
  final int maxWords;
  final int minWordLength;
  final int maxWordLength;
  final int gridSize;
  final double similarityThreshold;

  const DifficultySettings({
    required this.level,
    required this.maxWords,
    required this.minWordLength,
    required this.maxWordLength,
    required this.gridSize,
    required this.similarityThreshold,
  });

  factory DifficultySettings.fromLevel(DifficultyLevel level) {
    return DifficultySettings(
      level: level,
      maxWords: level.maxWords,
      minWordLength: level.minWordLength,
      maxWordLength: level.maxWordLength,
      gridSize: level.gridSize,
      similarityThreshold: _getSimilarityThreshold(level),
    );
  }

  static double _getSimilarityThreshold(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 0.7; // High similarity = easier (word and clue are similar)
      case DifficultyLevel.medium:
        return 0.5; // Medium similarity
      case DifficultyLevel.hard:
        return 0.3; // Low similarity = harder (cryptic clues)
    }
  }
}