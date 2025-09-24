import 'package:flutter_test/flutter_test.dart';
import 'package:cruci_verba/services/word_similarity_service.dart';

void main() {
  group('WordSimilarityService Tests', () {
    late WordSimilarityService service;

    setUp(() {
      service = WordSimilarityService.instance;
    });

    test('calculateSimilarity should return 1.0 for exact word matches in clue', () {
      final similarity = service.calculateSimilarity('kedi', 'Bu bir kedi hayvanıdır');
      expect(similarity, equals(1.0));
    });

    test('calculateSimilarity should return 0.0 for empty inputs', () {
      expect(service.calculateSimilarity('', 'any clue'), equals(0.0));
      expect(service.calculateSimilarity('word', ''), equals(0.0));
      expect(service.calculateSimilarity('', ''), equals(0.0));
    });

    test('calculateSimilarity should handle Turkish character normalization', () {
      final similarity1 = service.calculateSimilarity('göz', 'GÖZ organı');
      final similarity2 = service.calculateSimilarity('ağaç', 'AĞAÇ bitki');

      expect(similarity1, greaterThan(0.7));
      expect(similarity2, greaterThan(0.7));
    });

    test('calculateSimilarity should recognize semantic relationships', () {
      // Animal words
      final animalSimilarity = service.calculateSimilarity('köpek', 'Evcil hayvan, hav hav der');
      expect(animalSimilarity, greaterThan(0.5));

      // Color words
      final colorSimilarity = service.calculateSimilarity('kırmızı', 'Renk, al gibi');
      expect(colorSimilarity, greaterThan(0.5));

      // Body parts
      final bodySimilarity = service.calculateSimilarity('kulak', 'İşitme organı');
      expect(bodySimilarity, greaterThan(0.5));
    });

    test('calculateSimilarity should handle Turkish suffix patterns', () {
      // Profession suffixes (-ci/-cı)
      final professionSimilarity = service.calculateSimilarity('öğretmenci', 'Eğitim işi yapan meslek');
      expect(professionSimilarity, greaterThan(0.4));

      // Having suffixes (-li/-lı)
      final havingSimilarity = service.calculateSimilarity('şekerli', 'Şeker ile olan');
      expect(havingSimilarity, greaterThan(0.4));

      // Without suffixes (-siz/-sız)
      final withoutSimilarity = service.calculateSimilarity('tatsız', 'Tat olmayan');
      expect(withoutSimilarity, greaterThan(0.4));
    });

    test('calculateSimilarity should consider word/clue length complexity', () {
      // Simple word with simple clue should have higher similarity
      final simpleSimilarity = service.calculateSimilarity('ev', 'Yaşanan yer');

      // Complex word with complex clue should have lower similarity
      final complexSimilarity = service.calculateSimilarity(
        'elektromagnetizma',
        'Elektrik ve manyetik alanların birbirleriyle etkileşimini inceleyen fizik dalı'
      );

      expect(simpleSimilarity, greaterThan(complexSimilarity));
    });

    test('calculateSimilarity should return values between 0.0 and 1.0', () {
      final testCases = [
        ['kedi', 'hayvan'],
        ['masa', 'mobilya'],
        ['güneş', 'yıldız'],
        ['bilgisayar', 'teknoloji'],
        ['xyz', 'abc def ghi'],
      ];

      for (final testCase in testCases) {
        final similarity = service.calculateSimilarity(testCase[0], testCase[1]);
        expect(similarity, greaterThanOrEqualTo(0.0));
        expect(similarity, lessThanOrEqualTo(1.0));
      }
    });

    test('classifyDifficulty should return correct difficulty labels', () {
      expect(service.classifyDifficulty(0.8), equals('Kolay'));
      expect(service.classifyDifficulty(0.7), equals('Kolay'));
      expect(service.classifyDifficulty(0.6), equals('Orta'));
      expect(service.classifyDifficulty(0.4), equals('Orta'));
      expect(service.classifyDifficulty(0.3), equals('Zor'));
      expect(service.classifyDifficulty(0.1), equals('Zor'));
    });

    test('calculateSimilarity should handle punctuation and whitespace', () {
      final similarity1 = service.calculateSimilarity('test', 'Bu bir test, değil mi?');
      final similarity2 = service.calculateSimilarity('test', 'Bu    bir   test   !');

      // Both should find the word despite punctuation and extra whitespace
      expect(similarity1, equals(1.0));
      expect(similarity2, equals(1.0));
    });

    test('calculateSimilarity should be consistent', () {
      // Same inputs should always return same results
      final word = 'kitap';
      final clue = 'Okuma materyali';

      final similarity1 = service.calculateSimilarity(word, clue);
      final similarity2 = service.calculateSimilarity(word, clue);
      final similarity3 = service.calculateSimilarity(word, clue);

      expect(similarity1, equals(similarity2));
      expect(similarity2, equals(similarity3));
    });

    test('WordSimilarityService should be singleton', () {
      final service1 = WordSimilarityService.instance;
      final service2 = WordSimilarityService.instance;

      expect(identical(service1, service2), isTrue);
    });
  });

  group('WordSimilarityService Edge Cases', () {
    late WordSimilarityService service;

    setUp(() {
      service = WordSimilarityService.instance;
    });

    test('calculateSimilarity should handle very long words and clues', () {
      final longWord = 'a' * 100;
      final longClue = 'b' * 1000;

      final similarity = service.calculateSimilarity(longWord, longClue);
      expect(similarity, greaterThanOrEqualTo(0.0));
      expect(similarity, lessThanOrEqualTo(1.0));
    });

    test('calculateSimilarity should handle special characters', () {
      final similarity = service.calculateSimilarity('test@123', 'Test #123 clue!');
      expect(similarity, greaterThanOrEqualTo(0.0));
      expect(similarity, lessThanOrEqualTo(1.0));
    });

    test('calculateSimilarity should handle Unicode characters', () {
      final similarity = service.calculateSimilarity('çğıöşü', 'ÇĞIÖŞÜçğıöşü');
      expect(similarity, greaterThan(0.0));
    });

    test('calculateSimilarity should handle single character words', () {
      final similarity = service.calculateSimilarity('a', 'b c d e f');
      expect(similarity, greaterThanOrEqualTo(0.0));
      expect(similarity, lessThanOrEqualTo(1.0));
    });
  });
}