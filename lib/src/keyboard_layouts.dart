import 'package:flutter/widgets.dart';

/// A localized alphabetic layout: any number of base rows plus an optional
/// shift layer. Cased scripts (Latin, Cyrillic) leave [shiftRows] null and get
/// an automatic uppercase shift; non-cased scripts (Devanagari, Arabic) supply
/// an explicit secondary layer. [rtl] marks right-to-left scripts (the typed
/// text flows RTL via the framework's bidi; the keyboard itself renders LTR).
///
/// Adding a language is pure data — define a [KbLayout] and pass it in the
/// `layouts:` list. Rows may have any length and there may be any number of
/// them, so 3-row (Latin) and 4-row (Thai) scripts both work.
@immutable
class KbLayout {
  const KbLayout({
    required this.code,
    required this.label,
    required this.rtl,
    required this.rows,
    this.shiftRows,
  });

  /// Short language code: 'en', 'hi', 'ar', 'ru', …
  final String code;

  /// Glyph shown on the language-switch key (e.g. 'EN', 'हिं', 'ع', 'RU').
  final String label;

  /// True for right-to-left scripts (Arabic, …).
  final bool rtl;

  /// Base rows.
  final List<List<String>> rows;

  /// Shift-layer rows; when null, shift uppercases [rows].
  final List<List<String>>? shiftRows;
}

const KbLayout kbEnglish = KbLayout(
  code: 'en',
  label: 'EN',
  rtl: false,
  rows: [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ],
);

const KbLayout kbHindi = KbLayout(
  code: 'hi',
  label: 'हिं',
  rtl: false,
  // Base = consonants; shift = independent vowels, mātrās and signs.
  rows: [
    ['क', 'ख', 'ग', 'घ', 'च', 'छ', 'ज', 'झ', 'ट', 'ठ'],
    ['ड', 'ढ', 'ण', 'त', 'थ', 'द', 'ध', 'न', 'प', 'फ'],
    ['ब', 'भ', 'म', 'य', 'र', 'ल', 'व', 'स', 'ह', 'क्ष'],
  ],
  shiftRows: [
    ['अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ए', 'ऐ', 'ओ', 'औ'],
    ['ा', 'ि', 'ी', 'ु', 'ू', 'े', 'ै', 'ो', 'ौ', 'ं'],
    ['्', 'ः', 'ँ', '़', 'श', 'ष', 'ङ', 'ञ', 'ड़', 'ढ़'],
  ],
);

const KbLayout kbArabic = KbLayout(
  code: 'ar',
  label: 'ع',
  rtl: true,
  // Standard Arabic layout; shift = hamza forms, harakāt and punctuation.
  rows: [
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج'],
    ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك', 'ط'],
    ['ئ', 'ء', 'ؤ', 'ر', 'لا', 'ى', 'ة', 'و', 'ز', 'ظ', 'د'],
  ],
  shiftRows: [
    ['أ', 'إ', 'آ', 'ء', 'ئ', 'ؤ', 'ة', 'ى', 'لآ', 'ذ', 'ط'],
    ['َ', 'ً', 'ُ', 'ٌ', 'ِ', 'ٍ', 'ّ', 'ْ', 'ـ', 'ٰ', 'ٕ'],
    ['،', '؛', '؟', '٪', '«', '»', '”', '“', '…', '-', 'ٔ'],
  ],
);

const KbLayout kbRussian = KbLayout(
  code: 'ru',
  label: 'RU',
  rtl: false,
  // Standard ЙЦУКЕН layout; cased, so shift auto-uppercases.
  rows: [
    ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ'],
    ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
    ['я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'ё'],
  ],
);

/// Font fallbacks so non-Latin glyphs render even where the host's app font
/// has none. The first entries are the **bundled** Noto fonts (shipped as
/// package assets → guaranteed); the rest are common OS-installed fonts.
const List<String> kbScriptFontFallback = [
  // Bundled package assets (guaranteed).
  'NotoSansDevanagari',
  'NotoSansArabic',
  // OS-installed fallbacks.
  'Noto Sans Devanagari',
  'Nirmala UI',
  'Kohinoor Devanagari',
  'Mangal',
  'Noto Sans Arabic',
  'Geeza Pro',
  'Segoe UI',
  'Tahoma',
  'Arial Unicode MS',
];

/// The built-in, glyph-verified layouts shipped with the package.
const List<KbLayout> kPolyboardDefaultLayouts = [
  kbEnglish,
  kbHindi,
  kbArabic,
  kbRussian,
];

KbLayout kbLayoutByCode(String code, List<KbLayout> layouts) =>
    layouts.firstWhere((l) => l.code == code, orElse: () => layouts.first);

/// First-strong-character text direction (Unicode bidi heuristic): RTL when the
/// first strongly-directional character is RTL (Arabic/Hebrew), LTR when it's
/// LTR, or null when only neutral characters (digits/punctuation) — so the
/// field keeps the ambient direction. Lets a field auto-flip to right-aligned
/// once RTL text is typed.
TextDirection? firstStrongTextDirection(String text) {
  for (final r in text.runes) {
    if ((r >= 0x0590 && r <= 0x05FF) ||
        (r >= 0x0600 && r <= 0x08FF) ||
        (r >= 0xFB1D && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF)) {
      return TextDirection.rtl;
    }
    if ((r >= 0x0041 && r <= 0x058F) ||
        (r >= 0x0900 && r <= 0x10FF) ||
        (r >= 0x1E00 && r <= 0x2BFF)) {
      return TextDirection.ltr;
    }
  }
  return null;
}
