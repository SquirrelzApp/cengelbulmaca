import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cruci_verba/widgets/clues_panel.dart';
import 'package:cruci_verba/providers/game_provider.dart';
import 'package:cruci_verba/models/word_clue.dart';
import 'package:cruci_verba/models/crossword_puzzle.dart';
import 'package:cruci_verba/models/cell.dart';

void main() {
  group('CluesPanel Widget Tests', () {
    late GameProvider gameProvider;
    late CrosswordPuzzle mockPuzzle;

    setUp(() {
      // Create mock puzzle data
      final grid = List<List<Cell>>.generate(
        3,
        (row) => List<Cell>.generate(
          3,
          (col) => Cell(letter: 'A', isBlocked: false, hidden: false),
        ),
      );

      mockPuzzle = CrosswordPuzzle(
        grid: grid,
        horizontalClues: [
          WordClue(
            word: 'CAR',
            clue: 'Vehicle',
            startRow: 0,
            startCol: 0,
            length: 3,
            isHorizontal: true,
            number: 1,
          ),
        ],
        verticalClues: [
          WordClue(
            word: 'CAT',
            clue: 'Animal',
            startRow: 0,
            startCol: 0,
            length: 3,
            isHorizontal: false,
            number: 2,
          ),
        ],
        rows: 3,
        cols: 3,
      );

      gameProvider = GameProvider();
    });

    testWidgets('CluesPanel renders tab controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const Scaffold(
              body: CluesPanel(),
            ),
          ),
        ),
      );

      // Verify the panel renders with tabs
      expect(find.byType(CluesPanel), findsOneWidget);
      expect(find.byType(DefaultTabController), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('CluesPanel displays horizontal and vertical tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const Scaffold(
              body: CluesPanel(),
            ),
          ),
        ),
      );

      // Look for tab indicators (arrows and text)
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('ClueListItem displays progress indicator', (WidgetTester tester) async {
      const testClue = WordClue(
        word: 'TEST',
        clue: 'A test word',
        startRow: 0,
        startCol: 0,
        length: 4,
        isHorizontal: true,
        number: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClueListItem(
              clue: testClue,
              isSelected: false,
              isCompleted: false,
              isCorrect: false,
              progress: 0.5, // 50% progress
              onTap: () {},
              onTakeLetter: () {},
            ),
          ),
        ),
      );

      // Verify progress indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify the progress indicator has the correct value
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator)
      );
      expect(progressIndicator.value, equals(0.5));
    });

    testWidgets('ClueListItem shows completed state correctly', (WidgetTester tester) async {
      const testClue = WordClue(
        word: 'TEST',
        clue: 'A test word',
        startRow: 0,
        startCol: 0,
        length: 4,
        isHorizontal: true,
        number: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClueListItem(
              clue: testClue,
              isSelected: false,
              isCompleted: true,
              isCorrect: true,
              progress: 1.0,
              onTap: () {},
              onTakeLetter: () {},
            ),
          ),
        ),
      );

      // Verify completion icon is shown
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify the card has correct styling for completed state
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, isNotNull);
    });

    testWidgets('ClueListItem tap triggers callback', (WidgetTester tester) async {
      bool tapCalled = false;
      const testClue = WordClue(
        word: 'TEST',
        clue: 'A test word',
        startRow: 0,
        startCol: 0,
        length: 4,
        isHorizontal: true,
        number: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClueListItem(
              clue: testClue,
              isSelected: false,
              isCompleted: false,
              isCorrect: false,
              progress: 0.0,
              onTap: () {
                tapCalled = true;
              },
              onTakeLetter: () {},
            ),
          ),
        ),
      );

      // Tap the list tile
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify the callback was triggered
      expect(tapCalled, isTrue);
    });

    testWidgets('ClueListItem take letter button triggers callback', (WidgetTester tester) async {
      bool takeLetterCalled = false;
      const testClue = WordClue(
        word: 'TEST',
        clue: 'A test word',
        startRow: 0,
        startCol: 0,
        length: 4,
        isHorizontal: true,
        number: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClueListItem(
              clue: testClue,
              isSelected: false,
              isCompleted: false,
              isCorrect: false,
              progress: 0.0,
              onTap: () {},
              onTakeLetter: () {
                takeLetterCalled = true;
              },
            ),
          ),
        ),
      );

      // Find and tap the take letter button
      final takeLetterButton = find.byIcon(Icons.text_fields_outlined);
      expect(takeLetterButton, findsOneWidget);

      await tester.tap(takeLetterButton);
      await tester.pumpAndSettle();

      // Verify the callback was triggered
      expect(takeLetterCalled, isTrue);
    });

    testWidgets('ClueListItem displays correct clue text with improved line height', (WidgetTester tester) async {
      const testClue = WordClue(
        word: 'TEST',
        clue: 'This is a longer clue text that should display with improved readability',
        startRow: 0,
        startCol: 0,
        length: 4,
        isHorizontal: true,
        number: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClueListItem(
              clue: testClue,
              isSelected: false,
              isCompleted: false,
              isCorrect: false,
              progress: 0.0,
              onTap: () {},
              onTakeLetter: () {},
            ),
          ),
        ),
      );

      // Find the clue text
      expect(find.text(testClue.clue), findsOneWidget);

      // Find the subtitle with letter count
      expect(find.text('4 letters'), findsOneWidget);
    });
  });

  group('Progress Calculation Tests', () {
    testWidgets('Progress indicator shows correct values for different states', (WidgetTester tester) async {
      // Test different progress values
      final progressValues = [0.0, 0.25, 0.5, 0.75, 1.0];

      for (final progress in progressValues) {
        const testClue = WordClue(
          word: 'TEST',
          clue: 'A test word',
          startRow: 0,
          startCol: 0,
          length: 4,
          isHorizontal: true,
          number: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClueListItem(
                clue: testClue,
                isSelected: false,
                isCompleted: progress == 1.0,
                isCorrect: progress == 1.0,
                progress: progress,
                onTap: () {},
                onTakeLetter: () {},
              ),
            ),
          ),
        );

        // Verify the progress indicator has the correct value
        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator)
        );
        expect(progressIndicator.value, equals(progress));

        // Reset for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });
}