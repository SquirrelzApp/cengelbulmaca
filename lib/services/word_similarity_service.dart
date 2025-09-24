import '../utils/turkish_casing.dart';

class WordSimilarityService {
  static WordSimilarityService? _instance;
  static WordSimilarityService get instance {
    _instance ??= WordSimilarityService._internal();
    return _instance!;
  }

  WordSimilarityService._internal();

  /// Calculate similarity between a word and its clue/meaning.
  /// Returns a value between 0.0 (completely different) and 1.0 (identical).
  /// Higher similarity means easier difficulty.
  double calculateSimilarity(String word, String clue) {
    if (word.isEmpty || clue.isEmpty) return 0.0;

    final normalizedWord = _normalizeText(word);
    final normalizedClue = _normalizeText(clue);

    // Check for exact word match in clue (easiest case)
    if (normalizedClue.contains(normalizedWord)) {
      return 1.0;
    }

    // Check for partial word matches
    final clueParts = normalizedClue.split(' ');

    double partialMatchScore = 0.0;
    for (final part in clueParts) {
      if (part.length >= 3) { // Only consider meaningful parts
        final similarity = _calculateStringDistance(normalizedWord, part);
        if (similarity > partialMatchScore) {
          partialMatchScore = similarity;
        }
      }
    }

    // Check for common word patterns and meanings
    final semanticScore = _calculateSemanticSimilarity(normalizedWord, normalizedClue);

    // Combine scores with weights
    final combinedScore = (partialMatchScore * 0.6) + (semanticScore * 0.4);

    return combinedScore.clamp(0.0, 1.0);
  }

  /// Calculate semantic similarity based on Turkish word patterns
  double _calculateSemanticSimilarity(String word, String clue) {
    // Common Turkish word-meaning patterns for easier difficulty classification
    final easyPatterns = <String, List<String>>{
      // Colors
      'kırmızı': ['kırmızı', 'renk', 'al'],
      'mavi': ['mavi', 'renk', 'gök'],
      'yeşil': ['yeşil', 'renk', 'ot'],
      'sarı': ['sarı', 'renk', 'altın'],

      // Animals
      'kedi': ['kedi', 'hayvan', 'miyav'],
      'köpek': ['köpek', 'hayvan', 'hav'],
      'kuş': ['kuş', 'hayvan', 'uç', 'kanat'],
      'balık': ['balık', 'hayvan', 'su', 'yüz'],

      // Body parts
      'göz': ['göz', 'organ', 'gör', 'bak'],
      'kulak': ['kulak', 'organ', 'duy', 'işit'],
      'el': ['el', 'organ', 'tut', 'parmak'],
      'ayak': ['ayak', 'organ', 'yürü', 'adım'],

      // Common objects
      'masa': ['masa', 'mobilya', 'üstü'],
      'sandalye': ['sandalye', 'mobilya', 'otur'],
      'kitap': ['kitap', 'oku', 'sayfa'],
      'kalem': ['kalem', 'yaz', 'mürekkep'],
    };

    double baseScore = 0.0;

    // Check if word matches any easy patterns
    final wordLower = word.toLowerCase();
    if (easyPatterns.containsKey(wordLower)) {
      final patterns = easyPatterns[wordLower]!;
      for (final pattern in patterns) {
        if (clue.toLowerCase().contains(pattern)) {
          baseScore = 0.8; // High similarity for direct pattern matches
          break;
        }
      }
    }

    // Check for partial word matches in clue for common words
    if (baseScore == 0.0) {
      final commonWords = ['hayvan', 'evcil', 'renk', 'organ', 'mobilya', 'oku', 'yaz'];
      for (final common in commonWords) {
        if (clue.toLowerCase().contains(common)) {
          baseScore = 0.6; // Medium similarity for category words
          break;
        }
      }
    }

    // Check for common Turkish suffixes and root words
    final suffixScore = _checkTurkishSuffixes(word, clue);

    // Check for word length vs clue complexity
    final lengthComplexityScore = _calculateLengthComplexity(word, clue);

    // Combine scores with proper weighting
    final combinedScore = (baseScore * 0.5) + (suffixScore * 0.3) + (lengthComplexityScore * 0.2);

    return combinedScore.clamp(0.0, 1.0);
  }

  /// Check Turkish word suffixes for semantic relationships
  double _checkTurkishSuffixes(String word, String clue) {
    // Common Turkish suffixes and their meanings
    final suffixPatterns = <String, List<String>>{
      'ci': ['işi', 'meslek', 'yapan', 'çalış'], // -ci/-cı (profession)
      'cı': ['işi', 'meslek', 'yapan', 'çalış'],
      'li': ['olan', 'ile', 'sahip', 'bulunan'], // -li/-lı (having)
      'lı': ['olan', 'ile', 'sahip', 'bulunan'],
      'siz': ['olmayan', 'yok', 'eksik'], // -siz/-sız (without)
      'sız': ['olmayan', 'yok', 'eksik'],
      'lik': ['durum', 'hal', 'özellik'], // -lik/-lık (state)
      'lık': ['durum', 'hal', 'özellik'],
    };

    final wordLower = word.toLowerCase();
    final clueLower = clue.toLowerCase();

    for (final suffix in suffixPatterns.keys) {
      if (wordLower.endsWith(suffix) && wordLower.length > suffix.length + 2) {
        final meanings = suffixPatterns[suffix]!;
        for (final meaning in meanings) {
          if (clueLower.contains(meaning)) {
            return 0.5; // Moderate similarity for suffix matches
          }
        }
      }
    }

    return 0.0;
  }

  /// Calculate complexity based on word length vs clue length
  double _calculateLengthComplexity(String word, String clue) {
    final wordLength = word.length;
    final clueLength = clue.length;

    // Simple words with simple clues = high similarity (easy)
    if (wordLength <= 5 && clueLength <= 20) {
      return 0.7;
    }

    // Medium words with medium clues = medium similarity
    if (wordLength <= 8 && clueLength <= 40) {
      return 0.5;
    }

    // Long words with complex clues = low similarity (hard)
    return 0.3;
  }

  /// Calculate string distance similarity (Levenshtein-like)
  double _calculateStringDistance(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    final len1 = s1.length;
    final len2 = s2.length;
    final maxLen = len1 > len2 ? len1 : len2;

    // Simple character overlap calculation
    int matchCount = 0;
    final shorter = len1 < len2 ? s1 : s2;
    final longer = len1 < len2 ? s2 : s1;

    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matchCount++;
      }
    }

    return matchCount / maxLen;
  }

  /// Normalize Turkish text for comparison
  String _normalizeText(String text) {
    return toLowerTr(text)
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Classify difficulty based on similarity score
  String classifyDifficulty(double similarity) {
    if (similarity >= 0.7) return 'Kolay';
    if (similarity >= 0.4) return 'Orta';
    return 'Zor';
  }
}