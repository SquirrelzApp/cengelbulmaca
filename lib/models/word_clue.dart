class WordClue {
  final String word;
  final String clue;
  final int startRow;
  final int startCol;
  final int length;
  final bool isHorizontal;
  final int number;

  const WordClue({
    required this.word,
    required this.clue,
    required this.startRow,
    required this.startCol,
    required this.length,
    required this.isHorizontal,
    required this.number,
  });

  @override
  String toString() {
    return 'WordClue(word: $word, clue: $clue, start: ($startRow,$startCol), '
           'horizontal: $isHorizontal, number: $number)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordClue &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          startRow == other.startRow &&
          startCol == other.startCol &&
          isHorizontal == other.isHorizontal;

  @override
  int get hashCode =>
      word.hashCode ^ startRow.hashCode ^ startCol.hashCode ^ isHorizontal.hashCode;
}