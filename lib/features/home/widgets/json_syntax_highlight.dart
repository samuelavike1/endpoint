import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// JSON syntax colors matching VS Code dark theme
class JsonColors {
  static const Color key = Color(0xFF9CDCFE);       // light blue for keys
  static const Color stringVal = Color(0xFFCE9178); // orange for string values
  static const Color number = Color(0xFFB5CEA8);    // green for numbers
  static const Color boolVal = Color(0xFF569CD6);   // blue for booleans
  static const Color nullVal = Color(0xFF569CD6);   // blue for null
  static const Color bracket = Color(0xFFD4D4D4);   // white for brackets
  static const Color colon = Color(0xFFD4D4D4);     // white for colons
  static const Color comma = Color(0xFFD4D4D4);     // white for commas
}

/// A widget that displays JSON with syntax highlighting
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
    return SelectableText.rich(
      TextSpan(
        children: _highlight(source),
        style: GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  List<TextSpan> _highlight(String text) {
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
        while (nextNonSpace < length && (text[nextNonSpace] == ' ' || text[nextNonSpace] == '\t')) {
          nextNonSpace++;
        }

        if (nextNonSpace < length && text[nextNonSpace] == ':') {
          // It's a key
          spans.add(TextSpan(text: str, style: const TextStyle(color: JsonColors.key)));
        } else {
          // It's a string value
          spans.add(TextSpan(text: str, style: const TextStyle(color: JsonColors.stringVal)));
        }
        i = stringEnd + 1;
      } else if (char == ':') {
        spans.add(const TextSpan(text: ':', style: TextStyle(color: JsonColors.colon)));
        i++;
      } else if (char == ',' || char == '\n' || char == '\r') {
        spans.add(TextSpan(text: char, style: const TextStyle(color: JsonColors.comma)));
        i++;
      } else if (char == '{' || char == '}' || char == '[' || char == ']') {
        spans.add(TextSpan(text: char, style: const TextStyle(color: JsonColors.bracket)));
        i++;
      } else if (_isDigitOrMinus(char)) {
        // Number
        final numEnd = _findNumberEnd(text, i);
        final numStr = text.substring(i, numEnd);
        spans.add(TextSpan(text: numStr, style: const TextStyle(color: JsonColors.number)));
        i = numEnd;
      } else if (text.startsWith('true', i)) {
        spans.add(const TextSpan(text: 'true', style: TextStyle(color: JsonColors.boolVal)));
        i += 4;
      } else if (text.startsWith('false', i)) {
        spans.add(const TextSpan(text: 'false', style: TextStyle(color: JsonColors.boolVal)));
        i += 5;
      } else if (text.startsWith('null', i)) {
        spans.add(const TextSpan(text: 'null', style: TextStyle(color: JsonColors.nullVal)));
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
        i += 2; // skip escaped char
        continue;
      }
      if (text[i] == '"') return i;
      i++;
    }
    return text.length - 1;
  }

  int _findNumberEnd(String text, int start) {
    int i = start;
    while (i < text.length && (text[i] == '-' || text[i] == '+' || text[i] == '.' ||
        text[i] == 'e' || text[i] == 'E' ||
        (text.codeUnitAt(i) >= 48 && text.codeUnitAt(i) <= 57))) {
      i++;
    }
    return i;
  }

  bool _isDigitOrMinus(String char) {
    return char == '-' || (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57);
  }
}
