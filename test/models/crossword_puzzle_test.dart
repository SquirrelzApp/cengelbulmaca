import 'package:flutter_test/flutter_test.dart';
import 'package:cruci_verba/models/crossword_puzzle.dart';
import 'package:cruci_verba/models/word_clue.dart';
import 'package:cruci_verba/models/cell.dart';

void main() {
  group('CrosswordPuzzle Model Tests', () {
    late CrosswordPuzzle puzzle;
    late List<List<Cell>> grid;
    late List<WordClue> horizontalClues;
    late List<WordClue> verticalClues;

    setUp(() {
      // Create a 3x3 grid
      grid = List<List<Cell>>.generate(
        3,
        (row) => List<Cell>.generate(
          3,
          (col) => Cell(letter: 'A', isBlocked: false, hidden: false),
        ),
      );

      horizontalClues = [
        const WordClue(
          word: 'CAR',
          clue: 'Vehicle',
          startRow: 0,
          startCol: 0,
          length: 3,
          isHorizontal: true,
          number: 1,
        ),
      ];

      verticalClues = [
        const WordClue(
          word: 'CAT',
          clue: 'Animal',
          startRow: 0,
          startCol: 0,
          length: 3,
          isHorizontal: false,
          number: 2,
        ),
      ];

      puzzle = CrosswordPuzzle(
        grid: grid,
        horizontalClues: horizontalClues,
        verticalClues: verticalClues,
        rows: 3,
        cols: 3,
      );
    });

    test('getWordProgress returns correct progress for empty word', () {
      final progress = puzzle.getWordProgress(horizontalClues.first);
      expect(progress, equals(0.0));
    });

    test('getWordProgress returns correct progress for partially filled word', () {
      // Fill first cell
      puzzle.updateCellInput(0, 0, 'C');

      final progress = puzzle.getWordProgress(horizontalClues.first);
      expect(progress, closeTo(1.0 / 3.0, 0.01)); // 1 out of 3 cells filled
    });

    test('getWordProgress returns correct progress for fully filled word', () {
      // Fill all cells in the word
      puzzle.updateCellInput(0, 0, 'C');
      puzzle.updateCellInput(0, 1, 'A');
      puzzle.updateCellInput(0, 2, 'R');

      final progress = puzzle.getWordProgress(horizontalClues.first);
      expect(progress, equals(1.0));
    });

    test('getWordProgress works correctly for vertical words', () {
      // Fill first two cells of vertical word
      puzzle.updateCellInput(0, 0, 'C');
      puzzle.updateCellInput(1, 0, 'A');

      final progress = puzzle.getWordProgress(verticalClues.first);
      expect(progress, closeTo(2.0 / 3.0, 0.01)); // 2 out of 3 cells filled
    });

    test('getWordClueAt returns correct horizontal clue', () {
      final clue = puzzle.getWordClueAt(0, 1, true);
      expect(clue, equals(horizontalClues.first));
    });

    test('getWordClueAt returns correct vertical clue', () {
      final clue = puzzle.getWordClueAt(1, 0, false);
      expect(clue, equals(verticalClues.first));
    });

    test('getWordClueAt returns null for invalid position', () {
      final clue = puzzle.getWordClueAt(5, 5, true);
      expect(clue, isNull);
    });

    test('getWordCluesAt returns both clues for intersecting position', () {
      final clues = puzzle.getWordCluesAt(0, 0);
      expect(clues.length, equals(2));
      expect(clues.contains(horizontalClues.first), isTrue);
      expect(clues.contains(verticalClues.first), isTrue);
    });

    test('isValidPosition returns true for valid coordinates', () {
      expect(puzzle.isValidPosition(0, 0), isTrue);
      expect(puzzle.isValidPosition(2, 2), isTrue);
      expect(puzzle.isValidPosition(1, 1), isTrue);
    });

    test('isValidPosition returns false for invalid coordinates', () {
      expect(puzzle.isValidPosition(-1, 0), isFalse);
      expect(puzzle.isValidPosition(0, -1), isFalse);
      expect(puzzle.isValidPosition(3, 0), isFalse);
      expect(puzzle.isValidPosition(0, 3), isFalse);
    });

    test('updateCellInput correctly updates cell user input', () {
      puzzle.updateCellInput(0, 0, 'c');
      final cell = puzzle.getCellAt(0, 0);
      expect(cell?.userInput, equals('C')); // Should be uppercase
    });

    test('clearCellInput correctly clears cell user input', () {
      puzzle.updateCellInput(0, 0, 'C');
      puzzle.clearCellInput(0, 0);
      final cell = puzzle.getCellAt(0, 0);
      expect(cell?.userInput, isNull);
    });

    test('isWordCompleted returns true when all cells are filled', () {
      puzzle.updateCellInput(0, 0, 'C');
      puzzle.updateCellInput(0, 1, 'A');
      puzzle.updateCellInput(0, 2, 'R');

      expect(puzzle.isWordCompleted(horizontalClues.first), isTrue);
    });

    test('isWordCompleted returns false when not all cells are filled', () {
      puzzle.updateCellInput(0, 0, 'C');
      puzzle.updateCellInput(0, 1, 'A');
      // Don't fill the third cell

      expect(puzzle.isWordCompleted(horizontalClues.first), isFalse);
    });

    test('isWordCorrect returns true when word is correct', () {
      // Set correct letters in grid
      grid[0][0] = Cell(letter: 'C', isBlocked: false, hidden: false);
      grid[0][1] = Cell(letter: 'A', isBlocked: false, hidden: false);
      grid[0][2] = Cell(letter: 'R', isBlocked: false, hidden: false);

      // Set user inputs to match
      puzzle.updateCellInput(0, 0, 'C');
      puzzle.updateCellInput(0, 1, 'A');
      puzzle.updateCellInput(0, 2, 'R');

      expect(puzzle.isWordCorrect(horizontalClues.first), isTrue);
    });

    test('completionPercentage calculates correctly', () {
      // Initially no cells filled
      expect(puzzle.completionPercentage, equals(0.0));

      // Fill some cells correctly
      grid[0][0] = Cell(letter: 'C', isBlocked: false, hidden: false);
      puzzle.updateCellInput(0, 0, 'C');

      // Count non-blocked, non-hidden cells and calculate expected percentage
      int totalCells = 0;
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final cell = grid[row][col];
          if (!cell.isEmpty && !cell.isBlocked && !cell.isHidden) {
            totalCells++;
          }
        }
      }

      final expectedPercentage = totalCells > 0 ? 1.0 / totalCells : 0.0;
      expect(puzzle.completionPercentage, equals(expectedPercentage));
    });

    test('isCompleted returns true when all cells are correct', () {
      // Set up grid with correct letters
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          grid[row][col] = Cell(letter: 'A', isBlocked: false, hidden: false);
          puzzle.updateCellInput(row, col, 'A');
        }
      }

      expect(puzzle.isCompleted, isTrue);
    });

    test('allClues returns combined horizontal and vertical clues', () {
      final allClues = puzzle.allClues;
      expect(allClues.length, equals(2));
      expect(allClues.contains(horizontalClues.first), isTrue);
      expect(allClues.contains(verticalClues.first), isTrue);
    });
  });

  group('CrosswordPuzzle Edge Cases', () {
    test('getWordProgress handles invalid word positions gracefully', () {
      final grid = List<List<Cell>>.generate(
        2,
        (row) => List<Cell>.generate(
          2,
          (col) => Cell(letter: 'A', isBlocked: false, hidden: false),
        ),
      );

      final puzzle = CrosswordPuzzle(
        grid: grid,
        horizontalClues: [],
        verticalClues: [],
        rows: 2,
        cols: 2,
      );

      // Create a clue that extends beyond grid boundaries
      const invalidClue = WordClue(
        word: 'TOOLONG',
        clue: 'Too long for grid',
        startRow: 0,
        startCol: 0,
        length: 7, // Longer than grid width
        isHorizontal: true,
        number: 1,
      );

      final progress = puzzle.getWordProgress(invalidClue);
      expect(progress, equals(0.0)); // Should handle gracefully
    });

    test('getWordProgress handles zero-length words', () {
      final grid = List<List<Cell>>.generate(
        2,
        (row) => List<Cell>.generate(
          2,
          (col) => Cell(letter: 'A', isBlocked: false, hidden: false),
        ),
      );

      final puzzle = CrosswordPuzzle(
        grid: grid,
        horizontalClues: [],
        verticalClues: [],
        rows: 2,
        cols: 2,
      );

      const zeroLengthClue = WordClue(
        word: '',
        clue: 'Empty word',
        startRow: 0,
        startCol: 0,
        length: 0,
        isHorizontal: true,
        number: 1,
      );

      final progress = puzzle.getWordProgress(zeroLengthClue);
      expect(progress, equals(0.0));
    });
  });
}