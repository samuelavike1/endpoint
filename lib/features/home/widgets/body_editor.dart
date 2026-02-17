import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Auto-closing pairs for brackets/quotes
const Map<String, String> _closingPairs = {
  '{': '}',
  '[': ']',
  '(': ')',
  '"': '"',
  "'": "'",
};

class BodyEditor extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onPrettify;

  const BodyEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onPrettify,
  });

  @override
  State<BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends State<BodyEditor> {
  int _lineCount = 1;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateLineCount);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateLineCount() {
    final text = widget.controller.text;
    final count = '\n'.allMatches(text).length + 1;
    if (count != _lineCount) {
      setState(() => _lineCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'REQUEST BODY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),

              // Line count indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$_lineCount lines',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Prettify button
              _ToolButton(
                icon: Icons.auto_fix_high_outlined,
                label: 'Prettify',
                onTap: widget.onPrettify,
              ),
            ],
          ),
        ),

        // Editor with line numbers
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line numbers gutter
                          Container(
                            width: 40,
                            padding: const EdgeInsets.only(top: 16, right: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                _lineCount,
                                (i) => Text(
                                  '${i + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: AppColors.textTertiary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Text editor
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: _focusNode,
                              onChanged: widget.onChanged,
                              maxLines: null,
                              expands: true,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                              decoration: InputDecoration(
                                hintText: '{\n  "key": "value"\n}',
                                hintStyle: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: AppColors.textTertiary.withValues(
                                    alpha: 0.4,
                                  ),
                                  height: 1.6,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              textAlignVertical: TextAlignVertical.top,
                              inputFormatters: [
                                _BracketInputFormatter(),
                                _IndentationInputFormatter(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Toolbar
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ShortcutButton(
                          label: '{}',
                          onTap: () => _insertPair('{', '}'),
                        ),
                        const SizedBox(width: 8),
                        _ShortcutButton(
                          label: '[]',
                          onTap: () => _insertPair('[', ']'),
                        ),
                        const SizedBox(width: 8),
                        _ShortcutButton(
                          label: '" : "',
                          onTap: () => _insertText('" : "'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _insertText(String text) {
    final selection = widget.controller.selection;
    final newText = widget.controller.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _insertPair(String open, String close) {
    final selection = widget.controller.selection;
    final newText = widget.controller.text.replaceRange(
      selection.start,
      selection.end,
      '$open$close',
    );
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + open.length),
    );
  }
}

/// Input formatter that auto-inserts closing brackets and quotes
class _BracketInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only handle single character insertions
    if (newValue.text.length != oldValue.text.length + 1) {
      return newValue;
    }

    final insertedIndex = newValue.selection.baseOffset - 1;
    if (insertedIndex < 0 || insertedIndex >= newValue.text.length) {
      return newValue;
    }

    final inserted = newValue.text[insertedIndex];
    final closing = _closingPairs[inserted];

    if (closing == null) return newValue;

    // Don't auto-close if the character after cursor is already the closing char
    if (insertedIndex + 1 < newValue.text.length &&
        newValue.text[insertedIndex + 1] == closing) {
      return newValue;
    }

    // For quotes, check if we're closing an existing one
    if (inserted == '"' || inserted == "'") {
      final beforeCursor = newValue.text.substring(0, insertedIndex);
      final count = beforeCursor.split(inserted).length - 1;
      if (count.isOdd) return newValue; // closing existing quote
    }

    // Insert the closing character after cursor
    final newText =
        newValue.text.substring(0, insertedIndex + 1) +
        closing +
        newValue.text.substring(insertedIndex + 1);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertedIndex + 1),
    );
  }
}

/// Formatter that handles basic auto-indentation on new lines
class _IndentationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only verify if a newline was added
    if (newValue.text.length <= oldValue.text.length) return newValue;

    // Check if the change is a newline insertion
    final newCharIndex = newValue.selection.baseOffset - 1;
    if (newCharIndex < 0 || newValue.text[newCharIndex] != '\n') {
      return newValue;
    }

    // Get previous line
    final beforeNewLine = newValue.text.substring(0, newCharIndex);
    final lastLineIndex = beforeNewLine.lastIndexOf('\n') + 1;
    final lastLine = beforeNewLine.substring(lastLineIndex);

    // Calculate existing indentation
    int spaces = 0;
    for (int i = 0; i < lastLine.length; i++) {
      if (lastLine[i] == ' ') {
        spaces++;
      } else {
        break;
      }
    }

    // Check if we should increase indentation (line ends with { or [)
    final trimmedLine = lastLine.trimRight();
    if (trimmedLine.isNotEmpty) {
      final lastChar = trimmedLine[trimmedLine.length - 1];
      if (lastChar == '{' || lastChar == '[') {
        spaces += 2; // Increase indent
      }
    }

    // Construct indentation string
    final indent = ' ' * spaces;

    // Apply indentation
    final newText =
        newValue.text.substring(0, newCharIndex + 1) +
        indent +
        newValue.text.substring(newCharIndex + 1);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCharIndex + 1 + spaces),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ShortcutButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
