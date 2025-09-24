import 'crossword_puzzle.dart';
import 'word_clue.dart';

enum GameStatus {
  playing,
  paused,
  completed,
}

enum Direction {
  horizontal,
  vertical,
}

class SelectedCell {
  final int row;
  final int col;
  final Direction direction;

  const SelectedCell({
    required this.row,
    required this.col,
    required this.direction,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedCell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col &&
          direction == other.direction;

  @override
  int get hashCode => row.hashCode ^ col.hashCode ^ direction.hashCode;
}

class GameState {
  final CrosswordPuzzle puzzle;
  final GameStatus status;
  final SelectedCell? selectedCell;
  final WordClue? selectedWord;
  final Duration elapsedTime;
  final int lettersUsed;
  final List<WordClue> completedWords;
  final Map<String, bool> takenLetters;

  GameState({
    required this.puzzle,
    this.status = GameStatus.playing,
    this.selectedCell,
    this.selectedWord,
    this.elapsedTime = Duration.zero,
    this.lettersUsed = 0,
    this.completedWords = const [],
    this.takenLetters = const {},
  });

  GameState copyWith({
    CrosswordPuzzle? puzzle,
    GameStatus? status,
    SelectedCell? selectedCell,
    WordClue? selectedWord,
    Duration? elapsedTime,
    int? lettersUsed,
    List<WordClue>? completedWords,
    Map<String, bool>? takenLetters,
  }) {
    return GameState(
      puzzle: puzzle ?? this.puzzle,
      status: status ?? this.status,
      selectedCell: selectedCell ?? this.selectedCell,
      selectedWord: selectedWord ?? this.selectedWord,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      lettersUsed: lettersUsed ?? this.lettersUsed,
      completedWords: completedWords ?? this.completedWords,
      takenLetters: takenLetters ?? this.takenLetters,
    );
  }

  GameState clearSelection() {
    return copyWith(
      selectedCell: null,
      selectedWord: null,
    );
  }

  bool get isCompleted => puzzle.isCompleted;
  double get completionPercentage => puzzle.completionPercentage;
  
  bool isCellSelected(int row, int col) {
    return selectedCell != null && 
           selectedCell!.row == row && 
           selectedCell!.col == col;
  }

  bool isCellInSelectedWord(int row, int col) {
    if (selectedWord == null) return false;
    
    if (selectedWord!.isHorizontal) {
      return row == selectedWord!.startRow &&
             col >= selectedWord!.startCol &&
             col < selectedWord!.startCol + selectedWord!.length;
    } else {
      return col == selectedWord!.startCol &&
             row >= selectedWord!.startRow &&
             row < selectedWord!.startRow + selectedWord!.length;
    }
  }

  String get formattedTime {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60);
    final seconds = elapsedTime.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}