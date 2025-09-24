import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/crossword_puzzle.dart';
import '../models/word_clue.dart';
import '../models/difficulty_level.dart';
import '../services/crossword_generator_service.dart';
import '../utils/turkish_casing.dart';

class GameProvider with ChangeNotifier {
  GameState _gameState = GameState(
    puzzle: CrosswordPuzzle(
      grid: [],
      horizontalClues: [],
      verticalClues: [],
      rows: 0,
      cols: 0,
    ),
  );
  
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;
  DifficultyLevel _currentDifficulty = DifficultyLevel.medium;
  
  GameState get gameState => _gameState;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DifficultyLevel get currentDifficulty => _currentDifficulty;
  
  CrosswordPuzzle get puzzle => _gameState.puzzle;
  List<WordClue> get horizontalClues => puzzle.horizontalClues;
  List<WordClue> get verticalClues => puzzle.verticalClues;
  
  Future<void> newGame({int rows = 15, int cols = 15}) async {
    await newGameWithDifficulty(_currentDifficulty, rows: rows, cols: cols);
  }

  Future<void> newGameWithDifficulty(DifficultyLevel difficulty, {int rows = 15, int cols = 15}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentDifficulty = difficulty;
    notifyListeners();

    try {
      stopTimer();

      final difficultySettings = DifficultySettings.fromLevel(difficulty);
      final generatedPuzzle = await CrosswordGeneratorService.instance.generatePuzzleWithDifficulty(
        rows: rows,
        cols: cols,
        difficultySettings: difficultySettings,
      );

      _gameState = GameState(puzzle: generatedPuzzle);
      startTimer();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to generate puzzle: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  
  void selectCell(int row, int col, {Direction? preferredDirection}) {
    final cell = puzzle.getCellAt(row, col);
    if (cell == null || cell.isEmpty || cell.isBlocked || cell.isHidden) return;
    
    final wordClues = puzzle.getWordCluesAt(row, col);
    if (wordClues.isEmpty) return;
    
    WordClue? selectedWord;
    Direction direction = Direction.horizontal;
    
    if (wordClues.length == 1) {
      selectedWord = wordClues.first;
      direction = selectedWord.isHorizontal ? Direction.horizontal : Direction.vertical;
    } else {
      // Multiple words intersect at this cell
      if (preferredDirection != null) {
        selectedWord = wordClues.firstWhere(
          (clue) => clue.isHorizontal == (preferredDirection == Direction.horizontal),
          orElse: () => wordClues.first,
        );
        direction = preferredDirection;
      } else if (_gameState.selectedCell?.row == row && _gameState.selectedCell?.col == col) {
        // Toggle direction if same cell is selected
        final currentDirection = _gameState.selectedCell!.direction;
        direction = currentDirection == Direction.horizontal ? Direction.vertical : Direction.horizontal;
        selectedWord = wordClues.firstWhere(
          (clue) => clue.isHorizontal == (direction == Direction.horizontal),
          orElse: () => wordClues.first,
        );
      } else {
        selectedWord = wordClues.first;
        direction = selectedWord.isHorizontal ? Direction.horizontal : Direction.vertical;
      }
    }
    
    _gameState = _gameState.copyWith(
      selectedCell: SelectedCell(row: row, col: col, direction: direction),
      selectedWord: selectedWord,
    );
    
    notifyListeners();
  }
  
  void deselectCell() {
    _gameState = _gameState.copyWith(
      selectedCell: null,
      selectedWord: null,
    );
    // Notify that user wants to dismiss keyboard and unfocus
    notifyListeners();
  }
  
  void inputLetter(String letter) {
    if (_gameState.selectedCell == null || letter.isEmpty) return;
    
    final row = _gameState.selectedCell!.row;
    final col = _gameState.selectedCell!.col;
    
    puzzle.updateCellInput(row, col, toUpperTr(letter));
    
    // Move to next cell in selected word
    moveToNextCell();
    
    _checkForCompletion();
    notifyListeners();
  }
  
  void deleteLetter() {
    if (_gameState.selectedCell == null) return;

    final row = _gameState.selectedCell!.row;
    final col = _gameState.selectedCell!.col;
    final cell = puzzle.getCellAt(row, col);

    // If a horizontal word is selected, delete starting from the current
    // selection towards the left (including the current cell).
    final selectedWord = _gameState.selectedWord;
    if (selectedWord != null && _gameState.selectedCell!.direction == Direction.horizontal) {
      for (int c = col; c >= selectedWord.startCol; c--) {
        final scanCell = puzzle.getCellAt(selectedWord.startRow, c);
        if (scanCell != null && scanCell.hasUserInput) {
          puzzle.clearCellInput(selectedWord.startRow, c);
          // Move selection to the cleared cell
          _gameState = _gameState.copyWith(
            selectedCell: SelectedCell(row: selectedWord.startRow, col: c, direction: Direction.horizontal),
          );
          notifyListeners();
          return;
        }
      }
      // No filled cells to the left within the word
      notifyListeners();
      return;
    }

    // If a vertical word is selected, delete starting from the current
    // selection upwards (including the current cell).
    if (selectedWord != null && _gameState.selectedCell!.direction == Direction.vertical) {
      for (int r = row; r >= selectedWord.startRow; r--) {
        final scanCell = puzzle.getCellAt(r, selectedWord.startCol);
        if (scanCell != null && scanCell.hasUserInput) {
          puzzle.clearCellInput(r, selectedWord.startCol);
          // Move selection to the cleared cell
          _gameState = _gameState.copyWith(
            selectedCell: SelectedCell(row: r, col: selectedWord.startCol, direction: Direction.vertical),
          );
          notifyListeners();
          return;
        }
      }
      // No filled cells above within the word
      notifyListeners();
      return;
    }

    if (cell?.hasUserInput == true) {
      puzzle.clearCellInput(row, col);
    } else {
      // If current cell is empty, move to previous cell and delete
      moveToPreviousCell();
      final prevRow = _gameState.selectedCell?.row ?? row;
      final prevCol = _gameState.selectedCell?.col ?? col;
      puzzle.clearCellInput(prevRow, prevCol);
    }

    notifyListeners();
  }
  
  void moveToNextCell() {
    if (_gameState.selectedCell == null || _gameState.selectedWord == null) return;
    
    final currentRow = _gameState.selectedCell!.row;
    final currentCol = _gameState.selectedCell!.col;
    final direction = _gameState.selectedCell!.direction;
    final word = _gameState.selectedWord!;
    
    int nextRow = currentRow;
    int nextCol = currentCol;
    
    if (direction == Direction.horizontal) {
      nextCol++;
      if (nextCol >= word.startCol + word.length) {
        // Move to next word or wrap around
        return;
      }
    } else {
      nextRow++;
      if (nextRow >= word.startRow + word.length) {
        // Move to next word or wrap around
        return;
      }
    }
    
    if (puzzle.isValidPosition(nextRow, nextCol)) {
      _gameState = _gameState.copyWith(
        selectedCell: SelectedCell(row: nextRow, col: nextCol, direction: direction),
      );
    }
  }
  
  void moveToPreviousCell() {
    if (_gameState.selectedCell == null || _gameState.selectedWord == null) return;
    
    final currentRow = _gameState.selectedCell!.row;
    final currentCol = _gameState.selectedCell!.col;
    final direction = _gameState.selectedCell!.direction;
    final word = _gameState.selectedWord!;
    
    int prevRow = currentRow;
    int prevCol = currentCol;
    
    if (direction == Direction.horizontal) {
      prevCol--;
      if (prevCol < word.startCol) {
        // Move to previous word or stop
        return;
      }
    } else {
      prevRow--;
      if (prevRow < word.startRow) {
        // Move to previous word or stop
        return;
      }
    }
    
    if (puzzle.isValidPosition(prevRow, prevCol)) {
      _gameState = _gameState.copyWith(
        selectedCell: SelectedCell(row: prevRow, col: prevCol, direction: direction),
      );
    }
  }
  
  void clearSelection() {
    _gameState = _gameState.clearSelection();
    notifyListeners();
  }
  
  void takeLetter(int row, int col) {
    final cell = puzzle.getCellAt(row, col);
    if (cell == null || cell.isEmpty) return;
    
    puzzle.updateCellInput(row, col, cell.letter!);
    
    final takenLetters = Map<String, bool>.from(_gameState.takenLetters);
    takenLetters['$row,$col'] = true;
    
    _gameState = _gameState.copyWith(
      lettersUsed: _gameState.lettersUsed + 1,
      takenLetters: takenLetters,
    );
    
    _checkForCompletion();
    notifyListeners();
  }
  
  void takeRandomLetterFromWord(WordClue word) {
    // Get all unfilled positions in the word
    final List<Map<String, int>> availablePositions = [];
    
    for (int i = 0; i < word.length; i++) {
      final row = word.startRow + (word.isHorizontal ? 0 : i);
      final col = word.startCol + (word.isHorizontal ? i : 0);
      final cell = puzzle.getCellAt(row, col);
      
      if (cell != null && !cell.hasUserInput && !isLetterTaken(row, col)) {
        availablePositions.add({'row': row, 'col': col});
      }
    }
    
    if (availablePositions.isNotEmpty) {
      availablePositions.shuffle();
      final position = availablePositions.first;
      takeLetter(position['row']!, position['col']!);
    }
  }
  
  bool isLetterTaken(int row, int col) {
    return _gameState.takenLetters['$row,$col'] == true;
  }
  
  void _checkForCompletion() {
    if (puzzle.isCompleted) {
      _gameState = _gameState.copyWith(status: GameStatus.completed);
      stopTimer();
    }
  }
  
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _gameState = _gameState.copyWith(
        elapsedTime: _gameState.elapsedTime + const Duration(seconds: 1),
      );
      notifyListeners();
    });
  }
  
  void pauseGame() {
    stopTimer();
    _gameState = _gameState.copyWith(status: GameStatus.paused);
    notifyListeners();
  }
  
  void resumeGame() {
    if (_gameState.status == GameStatus.paused) {
      startTimer();
      _gameState = _gameState.copyWith(status: GameStatus.playing);
      notifyListeners();
    }
  }
  
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}
