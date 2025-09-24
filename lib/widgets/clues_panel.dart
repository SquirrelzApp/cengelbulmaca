import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/word_clue.dart';
import '../models/game_state.dart';

class CluesPanel extends StatelessWidget {
  const CluesPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final horizontalClues = gameProvider.horizontalClues;
        final verticalClues = gameProvider.verticalClues;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward, size: 16),
                            const SizedBox(width: 4),
                            Text('Across (${horizontalClues.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward, size: 16),
                            const SizedBox(width: 4),
                            Text('Down (${verticalClues.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tab views
                Expanded(
                  child: TabBarView(
                    children: [
                      CluesList(
                        clues: horizontalClues,
                        isHorizontal: true,
                      ),
                      CluesList(
                        clues: verticalClues,
                        isHorizontal: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CluesList extends StatelessWidget {
  final List<WordClue> clues;
  final bool isHorizontal;
  final VoidCallback? onCollapsePanel;

  const CluesList({
    Key? key,
    required this.clues,
    required this.isHorizontal,
    this.onCollapsePanel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (clues.isEmpty) {
      return const Center(
        child: Text(
          'No clues available',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;
        
        return ListView.builder(
          itemCount: clues.length,
          itemBuilder: (context, index) {
            final clue = clues[index];
            final isSelected = gameState.selectedWord == clue;
            final isCompleted = gameProvider.puzzle.isWordCompleted(clue);
            final isCorrect = gameProvider.puzzle.isWordCorrect(clue);
            
            final progress = gameProvider.puzzle.getWordProgress(clue);
            return ClueListItem(
              clue: clue,
              isSelected: isSelected,
              isCompleted: isCompleted,
              isCorrect: isCorrect,
              progress: progress,
              onTap: () => _selectClue(context, clue),
              onTakeLetter: () => _takeLetterFromWord(context, clue),
            );
          },
        );
      },
    );
  }

  void _selectClue(BuildContext context, WordClue clue) {
    final direction = isHorizontal ? Direction.horizontal : Direction.vertical;
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Select the word
    gameProvider.selectCell(clue.startRow, clue.startCol, preferredDirection: direction);
    
    // Collapse the panel using callback
    onCollapsePanel?.call();
  }


  void _takeLetterFromWord(BuildContext context, WordClue clue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Harf Al'),
          content: Text('Bu kelimeden rastgele bir harf almak istiyor musunuz?\nBu işlem harf sayacınızı artıracak.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<GameProvider>(context, listen: false)
                    .takeRandomLetterFromWord(clue);
              },
              child: const Text('Harf Al'),
            ),
          ],
        );
      },
    );
  }
}

class ClueListItem extends StatelessWidget {
  final WordClue clue;
  final bool isSelected;
  final bool isCompleted;
  final bool isCorrect;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onTakeLetter;

  const ClueListItem({
    Key? key,
    required this.clue,
    required this.isSelected,
    required this.isCompleted,
    required this.isCorrect,
    required this.progress,
    required this.onTap,
    required this.onTakeLetter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: isSelected ? 4.0 : 1.0,
      color: _getCardColor(),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            // Progress indicator background
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: _getProgressValue(),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                strokeWidth: 2.0,
              ),
            ),
            // Number circle
            CircleAvatar(
              backgroundColor: _getNumberBackgroundColor(),
              radius: 14,
              child: Text(
                '${clue.number}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getNumberTextColor(),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          clue.clue,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: _getTextColor(),
            decoration: isCorrect ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${clue.length} letters',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted)
              Icon(
                isCorrect ? Icons.check_circle : Icons.error,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
            IconButton(
              icon: const Icon(Icons.text_fields_outlined, size: 18),
              onPressed: onTakeLetter,
              tooltip: 'Harf al',
            ),
          ],
        ),
        onTap: onTap,
        selected: isSelected,
      ),
    );
  }

  Color _getCardColor() {
    if (isCorrect) {
      return Colors.green.shade50;
    } else if (isCompleted && !isCorrect) {
      return Colors.red.shade50;
    } else if (isSelected) {
      return Colors.blue.shade50;
    } else {
      return Colors.white;
    }
  }

  Color _getNumberBackgroundColor() {
    if (isCorrect) {
      return Colors.green;
    } else if (isCompleted && !isCorrect) {
      return Colors.red;
    } else if (isSelected) {
      return Colors.blue;
    } else {
      return Colors.grey.shade300;
    }
  }

  Color _getNumberTextColor() {
    if (isCorrect || (isCompleted && !isCorrect) || isSelected) {
      return Colors.white;
    } else {
      return Colors.black87;
    }
  }

  Color _getTextColor() {
    if (isCorrect) {
      return Colors.green.shade800;
    } else if (isCompleted && !isCorrect) {
      return Colors.red.shade800;
    } else {
      return Colors.black87;
    }
  }

  double _getProgressValue() {
    return progress;
  }

  Color _getProgressColor() {
    if (isCorrect) {
      return Colors.green;
    } else if (isCompleted && !isCorrect) {
      return Colors.red;
    } else {
      return Colors.blue.shade300;
    }
  }
}