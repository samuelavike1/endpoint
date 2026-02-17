import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// JSON syntax colors matching VS Code dark theme
/// JSON syntax colors matching VS Code theme (Dark/Light)
class JsonColors {
  // ── Keys ──
  static Color get key => AppColors.isDark
      ? const Color(0xFF38BDF8) // Light Blue 400 (Vivid Dark Mode)
      : const Color(0xFF0369A1); // Sky 700 (High Contrast Light Mode)

  // ── Strings ──
  static Color get stringVal => AppColors.isDark
      ? const Color(0xFFFF8A65) // Deep Orange 300
      : const Color(0xFFC2410C); // Orange 700

  // ── Numbers ──
  static Color get number => AppColors.isDark
      ? const Color(0xFF4ADE80) // Green 400
      : const Color(0xFF15803D); // Green 700

  // ── Booleans ──
  static Color get boolVal => AppColors.isDark
      ? const Color(0xFF818CF8) // Indigo 400
      : const Color(0xFF4338CA); // Indigo 700

  // ── Nulls ──
  static Color get nullVal => AppColors.isDark
      ? const Color(0xFF818CF8) // Indigo 400
      : const Color(0xFF4338CA); // Indigo 700

  // ── Punctuation ──
  static Color get bracket => AppColors.isDark
      ? const Color(0xFFD4D4D4) // Light Gray
      : const Color(0xFF374151); // Gray 700

  static Color get colon =>
      AppColors.isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151);

  static Color get comma =>
      AppColors.isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151);
}

/// A TextEditingController that highlights JSON syntax
class JsonSyntaxTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // If no style provided, use default
    final defaultStyle =
        style ??
        GoogleFonts.jetBrainsMono(
          fontSize: 12,
          height: 1.6,
          color: AppColors.textPrimary,
        );

    final children = highlight(text);

    return TextSpan(style: defaultStyle, children: children);
  }

  List<TextSpan> highlight(String text) {
    final spans = <TextSpan>[];
    final length = text.length;
    int i = 0;

    while (i < length) {
      final char = text[i];

      if (char == '"') {
        // Find the end of the string
        final stringEnd = _findStringEnd(text, i);
        final str = text.substring(i, stringEnd + 1);

        // Check if this is a key (next non-whitespace char after the string is ':')
        int nextNonSpace = stringEnd + 1;
        while (nextNonSpace < length &&
            (text[nextNonSpace] == ' ' ||
                text[nextNonSpace] == '\t' ||
                text[nextNonSpace] == '\n')) {
          nextNonSpace++;
        }

        if (nextNonSpace < length && text[nextNonSpace] == ':') {
          // It's a key
          spans.add(
            TextSpan(
              text: str,
              style: TextStyle(color: JsonColors.key),
            ),
          );
        } else {
          // It's a string value
          spans.add(
            TextSpan(
              text: str,
              style: TextStyle(color: JsonColors.stringVal),
            ),
          );
        }
        i = stringEnd + 1;
      } else if (char == ':') {
        spans.add(
          TextSpan(
            text: ':',
            style: TextStyle(color: JsonColors.colon),
          ),
        );
        i++;
      } else if (char == ',' || char == '\n' || char == '\r') {
        spans.add(
          TextSpan(
            text: char,
            style: TextStyle(color: JsonColors.comma),
          ),
        );
        i++;
      } else if (char == '{' || char == '}' || char == '[' || char == ']') {
        spans.add(
          TextSpan(
            text: char,
            style: TextStyle(color: JsonColors.bracket),
          ),
        );
        i++;
      } else if (_isDigitOrMinus(char)) {
        // Number
        final numEnd = _findNumberEnd(text, i);
        final numStr = text.substring(i, numEnd);
        spans.add(
          TextSpan(
            text: numStr,
            style: TextStyle(color: JsonColors.number),
          ),
        );
        i = numEnd;
      } else if (text.startsWith('true', i) && _isBoundary(text, i + 4)) {
        spans.add(
          TextSpan(
            text: 'true',
            style: TextStyle(color: JsonColors.boolVal),
          ),
        );
        i += 4;
      } else if (text.startsWith('false', i) && _isBoundary(text, i + 5)) {
        spans.add(
          TextSpan(
            text: 'false',
            style: TextStyle(color: JsonColors.boolVal),
          ),
        );
        i += 5;
      } else if (text.startsWith('null', i) && _isBoundary(text, i + 4)) {
        spans.add(
          TextSpan(
            text: 'null',
            style: TextStyle(color: JsonColors.nullVal),
          ),
        );
        i += 4;
      } else {
        // Whitespace or other
        spans.add(TextSpan(text: char));
        i++;
      }
    }

    return spans;
  }

  int _findStringEnd(String text, int start) {
    int i = start + 1;
    while (i < text.length) {
      if (text[i] == '\\') {
        if (i + 1 < text.length) {
          i += 2; // skip escaped char
        } else {
          i++;
        }
        continue;
      }
      if (text[i] == '"') return i;
      i++;
    }
    return text.length - 1;
  }

  int _findNumberEnd(String text, int start) {
    int i = start;
    while (i < text.length &&
        (text[i] == '-' ||
            text[i] == '+' ||
            text[i] == '.' ||
            text[i] == 'e' ||
            text[i] == 'E' ||
            (text.codeUnitAt(i) >= 48 && text.codeUnitAt(i) <= 57))) {
      i++;
    }
    return i;
  }

  bool _isDigitOrMinus(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return char == '-' || (code >= 48 && code <= 57);
  }

  bool _isBoundary(String text, int index) {
    if (index >= text.length) return true;
    final char = text[index];
    // Boundary is anything not alphanumeric or underscore (simplified)
    return !RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }
}

/// A widget that displays JSON with syntax highlighting (read-only)
class JsonSyntaxHighlight extends StatelessWidget {
  final String source;
  final double fontSize;

  const JsonSyntaxHighlight({
    super.key,
    required this.source,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Reuse logix from controller
    final spans = JsonSyntaxTextController().highlight(source);

    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
