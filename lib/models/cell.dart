import 'word_clue.dart';
import '../utils/turkish_casing.dart';

class Cell {
  final String? letter;
  final bool isBlocked;
  final int? number;
  String? userInput;
  final List<WordClue> containingWords;
  final bool isHidden;

  Cell({
    this.letter,
    this.isBlocked = false,
    this.number,
    this.userInput,
    this.containingWords = const [],
    bool hidden = false,
    @Deprecated('Use isHidden instead') bool isEmpty = false,
  }) : isHidden = hidden || isEmpty;

  Cell copyWith({
    String? letter,
    bool? isBlocked,
    int? number,
    String? userInput,
    List<WordClue>? containingWords,
    bool? isHidden,
  }) {
    return Cell(
      letter: letter ?? this.letter,
      isBlocked: isBlocked ?? this.isBlocked,
      number: number ?? this.number,
      userInput: userInput ?? this.userInput,
      containingWords: containingWords ?? this.containingWords,
      hidden: isHidden ?? this.isHidden,
    );
  }

  bool get isEmpty => letter == null || letter!.isEmpty;
  bool get shouldDisplay => !isHidden;
  bool get hasUserInput => userInput != null && userInput!.isNotEmpty;
  bool get isCorrect => hasUserInput &&
      letter != null &&
      toLowerTr(userInput!) == toLowerTr(letter!);
  bool get isStartOfWord => number != null;

  @override
  String toString() {
    return 'Cell(letter: $letter, blocked: $isBlocked, number: $number, input: $userInput)';
  }
}
