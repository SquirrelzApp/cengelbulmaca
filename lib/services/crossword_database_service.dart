import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/turkish_casing.dart';

class WordEntry {
  final String word;
  final String meaning;
  final String original;
  
  const WordEntry({
    required this.word,
    required this.meaning,
    required this.original,
  });
  
  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      original: json['original'] as String,
    );
  }
}

class CrosswordDatabaseService {
  static CrosswordDatabaseService? _instance;
  static CrosswordDatabaseService get instance {
    _instance ??= CrosswordDatabaseService._internal();
    return _instance!;
  }
  
  CrosswordDatabaseService._internal();
  
  Map<int, List<WordEntry>>? _wordsByLength;
  List<WordEntry>? _allWords;
  
  Future<void> initialize() async {
    if (_wordsByLength != null) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/crossword_db_optimized.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      _wordsByLength = {};
      _allWords = [];
      
      if (data.containsKey('words_by_length')) {
        final Map<String, dynamic> wordsByLength = data['words_by_length'];
        
        for (final lengthEntry in wordsByLength.entries) {
          final int length = int.tryParse(lengthEntry.key) ?? 0;
          if (length < 3) continue; // Skip very short words
          
          final Map<String, dynamic> wordsOfLength = lengthEntry.value;
          final List<WordEntry> words = [];
          
          for (final wordEntry in wordsOfLength.entries) {
            try {
              final Map<String, dynamic> wordData = wordEntry.value;
              if (wordData.containsKey('word') && wordData.containsKey('meaning')) {
                final word = WordEntry.fromJson(wordData);
                words.add(word);
                _allWords!.add(word);
              }
            } catch (e) {
              // Skip invalid entries
              continue;
            }
          }
          
          if (words.isNotEmpty) {
            _wordsByLength![length] = words;
          }
        }
      }
      
      print('Loaded ${_allWords!.length} words from database');
    } catch (e) {
      print('Error loading crossword database: $e');
      _wordsByLength = {};
      _allWords = [];
    }
  }
  
  List<WordEntry> getWordsByLength(int length) {
    if (_wordsByLength == null) return [];
    return _wordsByLength![length] ?? [];
  }
  
  List<WordEntry> getAllWords() {
    return _allWords ?? [];
  }
  
  WordEntry? getWordEntry(String word) {
    if (_allWords == null) return null;
    
    try {
      // Try match against original first (with Turkish characters)
      return _allWords!.firstWhere(
        (entry) => toLowerTr(entry.original) == toLowerTr(word),
        orElse: () => _allWords!.firstWhere(
          (entry2) => toLowerTr(entry2.word) == toLowerTr(word),
        ),
      );
    } catch (e) {
      return null;
    }
  }
  
  String? getMeaning(String word) {
    final entry = getWordEntry(word);
    return entry?.meaning;
  }
  
  List<WordEntry> getRandomWords(int count, {int? minLength, int? maxLength}) {
    if (_allWords == null || _allWords!.isEmpty) return [];
    
    List<WordEntry> filteredWords = _allWords!;
    
    if (minLength != null || maxLength != null) {
      filteredWords = _allWords!.where((word) {
        final length = word.word.length;
        if (minLength != null && length < minLength) return false;
        if (maxLength != null && length > maxLength) return false;
        return true;
      }).toList();
    }
    
    if (filteredWords.isEmpty) return [];
    
    filteredWords.shuffle();
    return filteredWords.take(count).toList();
  }
  
  List<int> getAvailableLengths() {
    if (_wordsByLength == null) return [];
    final lengths = _wordsByLength!.keys.toList()..sort();
    return lengths;
  }
  
  int get totalWordCount => _allWords?.length ?? 0;
  
  Map<int, int> get wordCountByLength {
    if (_wordsByLength == null) return {};
    
    final Map<int, int> counts = {};
    for (final entry in _wordsByLength!.entries) {
      counts[entry.key] = entry.value.length;
    }
    return counts;
  }
}
