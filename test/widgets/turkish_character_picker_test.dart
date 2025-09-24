import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cruci_verba/widgets/turkish_character_picker.dart';

void main() {
  group('TurkishCharacterPicker Widget Tests', () {
    testWidgets('TurkishCharacterPicker renders all Turkish characters', (WidgetTester tester) async {
      String? selectedCharacter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurkishCharacterPicker(
              onCharacterSelected: (char) {
                selectedCharacter = char;
              },
            ),
          ),
        ),
      );

      // Verify the picker renders
      expect(find.byType(TurkishCharacterPicker), findsOneWidget);

      // Verify all Turkish characters are displayed
      const turkishChars = ['Ç', 'Ğ', 'İ', 'Ö', 'Ş', 'Ü'];
      for (final char in turkishChars) {
        expect(find.text(char), findsOneWidget);
      }
    });

    testWidgets('Character selection triggers callback', (WidgetTester tester) async {
      String? selectedCharacter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurkishCharacterPicker(
              onCharacterSelected: (char) {
                selectedCharacter = char;
              },
            ),
          ),
        ),
      );

      // Tap on the 'Ç' character
      await tester.tap(find.text('Ç'));
      await tester.pumpAndSettle();

      // Verify the callback was triggered with correct character
      expect(selectedCharacter, equals('Ç'));
    });

    testWidgets('Close button triggers onClose callback', (WidgetTester tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurkishCharacterPicker(
              onCharacterSelected: (char) {},
              onClose: () {
                closeCalled = true;
              },
            ),
          ),
        ),
      );

      // Find and tap the close button
      final closeButton = find.byIcon(Icons.keyboard_hide);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify the close callback was triggered
      expect(closeCalled, isTrue);
    });

    testWidgets('Character buttons have proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurkishCharacterPicker(
              onCharacterSelected: (char) {},
            ),
          ),
        ),
      );

      // Find the first character button container
      final containerFinder = find.byType(Container).first;
      await tester.pumpAndSettle();

      // Verify the button has the expected size and styling
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.borderRadius, isNotNull);
      expect(decoration?.border, isNotNull);
    });

    testWidgets('Haptic feedback is triggered on character selection', (WidgetTester tester) async {
      // Set up haptic feedback testing
      final List<MethodCall> hapticCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        hapticCalls.add(methodCall);
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurkishCharacterPicker(
              onCharacterSelected: (char) {},
            ),
          ),
        ),
      );

      // Tap on a character
      await tester.tap(find.text('Ç'));
      await tester.pumpAndSettle();

      // Verify haptic feedback was called
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
        reason: 'Haptic feedback should be triggered on character selection'
      );

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('Picker has proper theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurkishCharacterPicker(
              onCharacterSelected: (char) {},
            ),
          ),
        ),
      );

      // Verify the main container has the correct theme colors
      final mainContainer = find.byType(Container).first;
      final container = tester.widget<Container>(mainContainer);
      final decoration = container.decoration as BoxDecoration?;

      // Check if the color matches the theme (_cardSurface)
      expect(decoration?.color, equals(const Color(0xFFF8F6F0)));
    });
  });
}