import 'persian_numbers.dart';

/// Search-only normalization. Original labels and typed user text are untouched.
abstract final class SearchText {
  static String normalize(String text) => PersianNumbers.toLatin(text)
      .toLowerCase()
      .replaceAll(RegExp('[يى]'), 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll(
        RegExp(
          r'[\u064b-\u065f\u0670\u0640\u200e\u200f\u202a-\u202e\u2066-\u2069]',
        ),
        '',
      )
      .replaceAll(RegExp(r'[\u200c\u200d]'), ' ')
      .replaceAll(RegExp('[،؛؟٪٫٬]'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9\u0621-\u06cc]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static String compact(String normalizedText) =>
      normalizedText.replaceAll(' ', '');
}
