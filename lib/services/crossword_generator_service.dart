import 'package:flutter/foundation.dart';
import '../classes/CrossWord.dart';
import '../models/crossword_puzzle.dart';
import '../models/word_clue.dart';
import '../models/cell.dart';
import '../models/difficulty_level.dart';
import 'crossword_database_service.dart';
import 'word_similarity_service.dart';
import '../utils/turkish_casing.dart';

// Top-level function for isolate computation
Future<Map<String, dynamic>> _generateCrosswordInIsolate(Map<String, dynamic> params) async {
  final gridRows = params['gridRows'] as int;
  final gridCols = params['gridCols'] as int;
  final wordStrings = params['wordStrings'] as List<String>;
  final maxWords = params['maxWords'] as int;
  final wordsData = params['wordsData'] as List<Map<String, dynamic>>;

  // Create the crossword using existing algorithm
  final crossword = Crossword(gridRows, gridCols);
  crossword.reset();

  // Generate crossword using existing algorithm
  int wordsAdded = 0;
  for (String word in wordStrings) {
    if (wordsAdded >= maxWords) break;
    if (!crossword.isCompleted()) {
      final added = crossword.addWord(word);
      if (added >= 0) {
        wordsAdded++;
      }
    } else {
      break;
    }
  }

  // Return serializable data instead of objects
  final board = crossword.getBoard();
  final starts = crossword.getStarts();

  return {
    'board': board,
    'starts': starts.map((s) => {
      'item1': s.Item1,
      'item2': s.Item2,
      'item3': s.Item3,
      'item4': s.Item4,
    }).toList(),
    'rows': crossword.getN(),
    'cols': crossword.getM(),
    'wordsData': wordsData,
  };
}

class CrosswordGeneratorService {
  static CrosswordGeneratorService? _instance;
  static CrosswordGeneratorService get instance {
    _instance ??= CrosswordGeneratorService._internal();
    return _instance!;
  }
  
  CrosswordGeneratorService._internal();

  final CrosswordDatabaseService _databaseService = CrosswordDatabaseService.instance;
  final WordSimilarityService _similarityService = WordSimilarityService.instance;
  
  Future<CrosswordPuzzle> generatePuzzle({
    int rows = 15,
    int cols = 15,
    int maxWords = 50,
  }) async {
    // Use medium difficulty as default
    final defaultSettings = DifficultySettings.fromLevel(DifficultyLevel.medium);
    return generatePuzzleWithDifficulty(
      rows: rows,
      cols: cols,
      difficultySettings: defaultSettings,
    );
  }

  Future<CrosswordPuzzle> generatePuzzleWithDifficulty({
    int rows = 15,
    int cols = 15,
    required DifficultySettings difficultySettings,
  }) async {
    await _databaseService.initialize();

    // Use grid size from difficulty settings
    final gridRows = difficultySettings.gridSize;
    final gridCols = difficultySettings.gridSize;

    // Get words based on difficulty settings
    final candidateWords = _databaseService.getRandomWords(
      difficultySettings.maxWords * 3, // Get more candidates to filter from
      minLength: difficultySettings.minWordLength,
      maxLength: difficultySettings.maxWordLength,
    );

    // Filter words based on difficulty (word-clue similarity)
    final filteredWords = _filterWordsByDifficulty(candidateWords, difficultySettings);

    // Use original (with Turkish characters), lowercase using Turkish-aware mapping
    final wordStrings = filteredWords.map((w) => toLowerTr(w.original)).toList();
    wordStrings.shuffle();

    // Convert words data to serializable format
    final wordsData = filteredWords.map((w) => {
      'original': w.original as String,
      'meaning': w.meaning as String,
    }).toList();

    // Prepare data for isolate
    final params = {
      'gridRows': gridRows,
      'gridCols': gridCols,
      'wordStrings': wordStrings.take(difficultySettings.maxWords).toList(),
      'maxWords': difficultySettings.maxWords,
      'wordsData': wordsData,
    };

    // Run heavy computation in isolate to avoid blocking UI
    final result = await compute(_generateCrosswordInIsolate, params);

    return _convertToGamePuzzleFromData(result);
  }

  /// Filter words based on difficulty settings using word-clue similarity
  List<dynamic> _filterWordsByDifficulty(List<dynamic> words, DifficultySettings settings) {
    switch (settings.level) {
      case DifficultyLevel.easy:
        // Easy: No filtering needed, just return first words
        // This ensures easy mode gets random words without filtering bias
        return words.take(settings.maxWords).toList();

      case DifficultyLevel.medium:
        // Medium: Light filtering - avoid very easy words (high similarity)
        return _filterWordsByMediumDifficulty(words, settings);

      case DifficultyLevel.hard:
        // Hard: Strong filtering - only cryptic/difficult words (low similarity)
        return _filterWordsByHardDifficulty(words, settings);
    }
  }

  /// Filter words for medium difficulty - exclude very easy words
  List<dynamic> _filterWordsByMediumDifficulty(List<dynamic> words, DifficultySettings settings) {
    final filteredWords = <dynamic>[];
    final rejectedWords = <dynamic>[];

    for (final wordData in words) {
      final word = wordData.original as String;
      final meaning = wordData.meaning as String;

      final similarity = _similarityService.calculateSimilarity(word, meaning);

      // Medium: exclude words with very high similarity (too easy)
      if (similarity < 0.8) {
        filteredWords.add(wordData);
      } else {
        rejectedWords.add(wordData); // Keep for backup
      }

      if (filteredWords.length >= settings.maxWords) {
        break;
      }
    }

    // If we don't have enough filtered words, add some rejected ones
    if (filteredWords.length < settings.maxWords) {
      final needed = settings.maxWords - filteredWords.length;
      filteredWords.addAll(rejectedWords.take(needed));
    }

    return filteredWords;
  }

  /// Filter words for hard difficulty - only cryptic/difficult words
  List<dynamic> _filterWordsByHardDifficulty(List<dynamic> words, DifficultySettings settings) {
    final hardWords = <dynamic>[];
    final mediumWords = <dynamic>[];
    final easyWords = <dynamic>[];

    for (final wordData in words) {
      final word = wordData.original as String;
      final meaning = wordData.meaning as String;

      final similarity = _similarityService.calculateSimilarity(word, meaning);

      // Categorize words by difficulty
      if (similarity <= 0.3) {
        hardWords.add(wordData); // Cryptic/difficult words
      } else if (similarity <= 0.6) {
        mediumWords.add(wordData); // Medium difficulty words
      } else {
        easyWords.add(wordData); // Easy words (backup only)
      }
    }

    // Build the final list prioritizing hard words
    final result = <dynamic>[];

    // First, add hard words
    result.addAll(hardWords.take(settings.maxWords));

    // If we need more, add medium words
    if (result.length < settings.maxWords) {
      final needed = settings.maxWords - result.length;
      result.addAll(mediumWords.take(needed));
    }

    // Last resort: add easy words if still not enough
    if (result.length < settings.maxWords) {
      final needed = settings.maxWords - result.length;
      result.addAll(easyWords.take(needed));
    }

    return result;
  }

  CrosswordPuzzle _convertToGamePuzzleFromData(Map<String, dynamic> data) {
    final board = data['board'] as List<List<String>>;
    final startsData = data['starts'] as List<Map<String, dynamic>>;
    final rows = data['rows'] as int;
    final cols = data['cols'] as int;
    final wordsData = data['wordsData'] as List<Map<String, dynamic>>;

    // Create word data map for lookup
    final wordsMap = <String, String>{};
    for (final wordData in wordsData) {
      wordsMap[wordData['original'] as String] = wordData['meaning'] as String;
    }

    // First, identify which positions are part of words
    final Set<String> wordPositions = <String>{};
    for (final startData in startsData) {
      final row = startData['item1'] as int;
      final col = startData['item2'] as int;
      final direction = startData['item3'] as int;
      final length = startData['item4'] as int;
      final isHorizontal = direction == 0;

      for (int i = 0; i < length; i++) {
        final r = row + (isHorizontal ? 0 : i);
        final c = col + (isHorizontal ? i : 0);
        if (r >= 0 && r < rows && c >= 0 && c < cols) {
          wordPositions.add('$r,$c');
        }
      }
    }

    // Create grid with proper cells, only showing cells that are part of words
    final grid = List<List<Cell>>.generate(
      rows,
      (row) => List<Cell>.generate(
        cols,
        (col) {
          final posKey = '$row,$col';
          final isPartOfWord = wordPositions.contains(posKey);
          final cellValue = board[row][col];

          if (!isPartOfWord && cellValue != '*') {
            // This cell is not part of any word and should be hidden
            return Cell(letter: null, isBlocked: false, hidden: true);
          }

          return Cell(
            letter: cellValue == ' ' || cellValue == '*' ? null : cellValue,
            isBlocked: cellValue == '*',
            hidden: false,
          );
        },
      ),
    );

    // Create word clues from starts
    final horizontalClues = <WordClue>[];
    final verticalClues = <WordClue>[];
    int clueNumber = 1;

    // Sort starts by position for consistent numbering
    final sortedStarts = startsData.toList()
      ..sort((a, b) {
        if (a['item1'] != b['item1']) return (a['item1'] as int).compareTo(b['item1'] as int);
        return (a['item2'] as int).compareTo(b['item2'] as int);
      });

    final Map<String, int> positionToNumber = {};

    for (final startData in sortedStarts) {
      final row = startData['item1'] as int;
      final col = startData['item2'] as int;
      final direction = startData['item3'] as int;
      final length = startData['item4'] as int;
      final isHorizontal = direction == 0;

      // Extract word from grid
      String word = '';
      for (int i = 0; i < length; i++) {
        final r = row + (isHorizontal ? 0 : i);
        final c = col + (isHorizontal ? i : 0);
        if (r < rows && c < cols && board[r][c] != ' ' && board[r][c] != '*') {
          word += board[r][c];
        }
      }

      if (word.isNotEmpty) {
        // Get position key for numbering
        final posKey = '$row,$col';
        int number = positionToNumber[posKey] ?? clueNumber++;
        if (!positionToNumber.containsKey(posKey)) {
          positionToNumber[posKey] = number;
          // Set number on the starting cell
          grid[row][col] = grid[row][col].copyWith(number: number);
        }

        // Get meaning from map
        final originalWord = toUpperTr(word);
        final meaning = wordsMap[originalWord] ??
                       wordsMap[word] ??
                       wordsMap[toLowerTr(word)] ??
                       'No clue available';

        final wordClue = WordClue(
          word: toUpperTr(word),
          clue: meaning,
          startRow: row,
          startCol: col,
          length: length,
          isHorizontal: isHorizontal,
          number: number,
        );

        if (isHorizontal) {
          horizontalClues.add(wordClue);
        } else {
          verticalClues.add(wordClue);
        }
      }
    }

    // Sort clues by number
    horizontalClues.sort((a, b) => a.number.compareTo(b.number));
    verticalClues.sort((a, b) => a.number.compareTo(b.number));

    return CrosswordPuzzle(
      grid: grid,
      horizontalClues: horizontalClues,
      verticalClues: verticalClues,
      rows: rows,
      cols: cols,
    );
  }

}
