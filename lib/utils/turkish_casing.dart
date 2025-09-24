/// Turkish-aware case conversion helpers.
/// Dart's built-in toUpperCase/toLowerCase are locale-insensitive and
/// mishandle i/I in Turkish. These helpers fix the common cases.

String toUpperTr(String input) {
  if (input.isEmpty) return input;
  // Map special Turkish letters before generic uppercasing
  // i -> İ, ı -> I
  final pre = input.replaceAll('i', 'İ').replaceAll('ı', 'I');
  return pre.toUpperCase();
}

String toLowerTr(String input) {
  if (input.isEmpty) return input;
  // Map special Turkish letters before generic lowercasing
  // İ -> i, I -> ı
  final pre = input.replaceAll('İ', 'i').replaceAll('I', 'ı');
  return pre.toLowerCase();
}

bool equalsIgnoreCaseTr(String a, String b) {
  return toLowerTr(a) == toLowerTr(b);
}

