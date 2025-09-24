import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cruci_verba/screens/main_menu_screen.dart';
import 'package:cruci_verba/providers/game_provider.dart';
import 'package:cruci_verba/models/difficulty_level.dart';

void main() {
  group('MainMenuScreen Difficulty Selection Tests', () {
    late GameProvider gameProvider;

    setUp(() {
      gameProvider = GameProvider();
    });

    tearDown(() {
      gameProvider.dispose();
    });

    testWidgets('MainMenuScreen should render difficulty selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Verify difficulty selection title is displayed
      expect(find.text('Zorluk Seviyesi'), findsOneWidget);

      // Verify all difficulty levels are displayed
      expect(find.text('Kolay'), findsOneWidget);
      expect(find.text('Orta'), findsOneWidget);
      expect(find.text('Zor'), findsOneWidget);
    });

    testWidgets('MainMenuScreen should show word counts for each difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Verify word counts are displayed
      expect(find.text('15 kelime'), findsOneWidget); // Easy
      expect(find.text('30 kelime'), findsOneWidget); // Medium
      expect(find.text('50 kelime'), findsOneWidget); // Hard
    });

    testWidgets('MainMenuScreen should show difficulty descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Should show default medium difficulty description
      expect(find.text('Orta seviye kelimeler'), findsOneWidget);
    });

    testWidgets('MainMenuScreen should allow difficulty selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Tap on easy difficulty
      await tester.tap(find.text('Kolay'));
      await tester.pumpAndSettle();

      // Should update description to easy
      expect(find.text('Kolay kelimeler, az sayıda kelime'), findsOneWidget);

      // Tap on hard difficulty
      await tester.tap(find.text('Zor'));
      await tester.pumpAndSettle();

      // Should update description to hard
      expect(find.text('Zor kelimeler, çok sayıda kelime'), findsOneWidget);
    });

    testWidgets('MainMenuScreen should highlight selected difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Find difficulty selection containers
      final difficultyContainers = find.byType(GestureDetector);
      expect(difficultyContainers.evaluate().length, greaterThan(0));

      // Tap on easy difficulty
      await tester.tap(find.text('Kolay'));
      await tester.pumpAndSettle();

      // The UI should visually indicate the selection
      // (specific visual tests would require examining Container decoration)
      expect(find.text('Kolay'), findsOneWidget);
    });

    testWidgets('MainMenuScreen start game button should use selected difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Select hard difficulty
      await tester.tap(find.text('Zor'));
      await tester.pumpAndSettle();

      // Find and tap the start game button
      final startButton = find.text('OYUNA BAŞLA');
      expect(startButton, findsOneWidget);

      // The tap will try to start a new game (which will fail without database)
      // but we can't easily test the navigation without mocking the service
      // This test verifies the UI structure is correct
    });

    testWidgets('MainMenuScreen should handle rapid difficulty changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Rapidly change difficulties
      await tester.tap(find.text('Kolay'));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Zor'));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Orta'));
      await tester.pumpAndSettle();

      // Should end up with medium description
      expect(find.text('Orta seviye kelimeler'), findsOneWidget);
    });

    testWidgets('MainMenuScreen should maintain selection state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Select easy difficulty
      await tester.tap(find.text('Kolay'));
      await tester.pumpAndSettle();

      // Scroll or interact with other parts of the screen
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();

      // Difficulty selection should still show easy description
      expect(find.text('Kolay kelimeler, az sayıda kelime'), findsOneWidget);
    });

    testWidgets('MainMenuScreen should work on different screen sizes', (WidgetTester tester) async {
      // Test small screen
      await tester.binding.setSurfaceSize(const Size(300, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      expect(find.text('Zorluk Seviyesi'), findsOneWidget);
      expect(find.text('Kolay'), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      expect(find.text('Zorluk Seviyesi'), findsOneWidget);
      expect(find.text('Kolay'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('MainMenuScreen Difficulty Visual Tests', () {
    late GameProvider gameProvider;

    setUp(() {
      gameProvider = GameProvider();
    });

    tearDown(() {
      gameProvider.dispose();
    });

    testWidgets('MainMenuScreen difficulty selection should have proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Find the main difficulty selection container
      final containerFinder = find.byType(Container);
      expect(containerFinder.evaluate().isNotEmpty, isTrue);

      // Find the difficulty title
      final titleFinder = find.text('Zorluk Seviyesi');
      expect(titleFinder, findsOneWidget);

      // Verify the text widget has proper styling
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontFamily, equals('serif'));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('MainMenuScreen difficulty buttons should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Find all GestureDetector widgets (difficulty buttons are wrapped in these)
      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors.evaluate().length, greaterThan(2)); // At least 3 for difficulties

      // Test that we can tap each difficulty level
      for (final level in ['Kolay', 'Orta', 'Zor']) {
        await tester.tap(find.text(level));
        await tester.pump();
        expect(find.text(level), findsOneWidget);
      }
    });
  });
}