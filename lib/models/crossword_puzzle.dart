import 'word_clue.dart';
import 'cell.dart';
import '../utils/turkish_casing.dart';

class CrosswordPuzzle {
  final List<List<Cell>> grid;
  final List<WordClue> horizontalClues;
  final List<WordClue> verticalClues;
  final int rows;
  final int cols;

  CrosswordPuzzle({
    required this.grid,
    required this.horizontalClues,
    required this.verticalClues,
    required this.rows,
    required this.cols,
  });

  List<WordClue> get allClues => [...horizontalClues, ...verticalClues];

  WordClue? getWordClueAt(int row, int col, bool isHorizontal) {
    final clues = isHorizontal ? horizontalClues : verticalClues;
    
    for (final clue in clues) {
      if (isHorizontal) {
        if (clue.startRow == row && 
            col >= clue.startCol && 
            col < clue.startCol + clue.length) {
          return clue;
        }
      } else {
        if (clue.startCol == col && 
            row >= clue.startRow && 
            row < clue.startRow + clue.length) {
          return clue;
        }
      }
    }
    return null;
  }

  List<WordClue> getWordCluesAt(int row, int col) {
    final clues = <WordClue>[];
    final horizontalClue = getWordClueAt(row, col, true);
    final verticalClue = getWordClueAt(row, col, false);
    
    if (horizontalClue != null) clues.add(horizontalClue);
    if (verticalClue != null) clues.add(verticalClue);
    
    return clues;
  }

  bool isValidPosition(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  Cell? getCellAt(int row, int col) {
    if (!isValidPosition(row, col)) return null;
    return grid[row][col];
  }

  void updateCellInput(int row, int col, String input) {
    if (!isValidPosition(row, col)) return;
    grid[row][col].userInput = toUpperTr(input);
  }

  void clearCellInput(int row, int col) {
    if (!isValidPosition(row, col)) return;
    grid[row][col].userInput = null;
  }

  bool isWordCompleted(WordClue wordClue) {
    for (int i = 0; i < wordClue.length; i++) {
      int row = wordClue.startRow + (wordClue.isHorizontal ? 0 : i);
      int col = wordClue.startCol + (wordClue.isHorizontal ? i : 0);
      
      final cell = getCellAt(row, col);
      if (cell == null || !cell.hasUserInput) {
        return false;
      }
    }
    return true;
  }

  bool isWordCorrect(WordClue wordClue) {
    if (!isWordCompleted(wordClue)) return false;
    
    for (int i = 0; i < wordClue.length; i++) {
      int row = wordClue.startRow + (wordClue.isHorizontal ? 0 : i);
      int col = wordClue.startCol + (wordClue.isHorizontal ? i : 0);
      
      final cell = getCellAt(row, col);
      if (cell == null || !cell.isCorrect) {
        return false;
      }
    }
    return true;
  }

  double get completionPercentage {
    int totalCells = 0;
    int correctCells = 0;
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cell = getCellAt(row, col);
        if (cell != null && !cell.isEmpty && !cell.isBlocked && !cell.isHidden) {
          totalCells++;
          if (cell.isCorrect) {
            correctCells++;
          }
        }
      }
    }
    
    return totalCells > 0 ? correctCells / totalCells : 0.0;
  }

  bool get isCompleted {
    return completionPercentage == 1.0;
  }

  double getWordProgress(WordClue wordClue) {
    int filledCells = 0;
    int totalCells = wordClue.length;

    for (int i = 0; i < wordClue.length; i++) {
      int row = wordClue.startRow + (wordClue.isHorizontal ? 0 : i);
      int col = wordClue.startCol + (wordClue.isHorizontal ? i : 0);

      final cell = getCellAt(row, col);
      if (cell != null && cell.hasUserInput) {
        filledCells++;
      }
    }

    return totalCells > 0 ? filledCells / totalCells : 0.0;
  }
}
