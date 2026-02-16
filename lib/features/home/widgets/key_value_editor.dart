import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/request_provider.dart';

class KeyValueEditor extends StatefulWidget {
  final String title;
  final String keyHint;
  final String valueHint;
  final List<KeyValuePair> initialPairs;
  final ValueChanged<List<KeyValuePair>> onChanged;

  const KeyValueEditor({
    super.key,
    required this.title,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
    this.initialPairs = const [],
    required this.onChanged,
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<_EditorRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [];
    if (widget.initialPairs.isNotEmpty) {
      for (final pair in widget.initialPairs) {
        _rows.add(_EditorRow(
          keyController: TextEditingController(text: pair.key),
          valueController: TextEditingController(text: pair.value),
          enabled: pair.enabled,
        ));
      }
    }
    _rows.add(_EditorRow(
      keyController: TextEditingController(),
      valueController: TextEditingController(),
    ));
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    // Auto-add new row if last row has content
    final lastRow = _rows.last;
    if (lastRow.keyController.text.isNotEmpty ||
        lastRow.valueController.text.isNotEmpty) {
      setState(() {
        _rows.add(_EditorRow(
          keyController: TextEditingController(),
          valueController: TextEditingController(),
        ));
      });
    }

    // Emit changes
    final pairs = <KeyValuePair>[];
    for (final row in _rows) {
      if (row.keyController.text.isNotEmpty || row.valueController.text.isNotEmpty) {
        pairs.add(KeyValuePair(
          key: row.keyController.text,
          value: row.valueController.text,
          enabled: row.enabled,
        ));
      }
    }
    widget.onChanged(pairs);
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
    _onChanged();
  }

  void _toggleRow(int index) {
    setState(() {
      _rows[index].enabled = !_rows[index].enabled;
    });
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_rows.where((r) => r.keyController.text.isNotEmpty && r.enabled).length}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: Text(
                  widget.keyHint.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.valueHint.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Rows
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _rows.length,
          itemBuilder: (context, index) {
            final row = _rows[index];
            final isLastRow = index == _rows.length - 1;
            final hasContent =
                row.keyController.text.isNotEmpty || row.valueController.text.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Row(
                children: [
                  // Toggle checkbox
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: isLastRow && !hasContent
                        ? Icon(Icons.add_circle_outline,
                            size: 16, color: AppColors.textTertiary)
                        : Checkbox(
                            value: row.enabled,
                            onChanged: (_) => _toggleRow(index),
                            activeColor: AppColors.primary,
                            side: BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                  ),
                  const SizedBox(width: 8),

                  // Key field
                  Expanded(
                    child: _CompactField(
                      controller: row.keyController,
                      hint: widget.keyHint,
                      enabled: row.enabled,
                      onChanged: (_) => _onChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Value field
                  Expanded(
                    child: _CompactField(
                      controller: row.valueController,
                      hint: widget.valueHint,
                      enabled: row.enabled,
                      onChanged: (_) => _onChanged(),
                    ),
                  ),

                  // Delete button
                  SizedBox(
                    width: 32,
                    child: isLastRow && !hasContent
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.close, size: 14),
                            color: AppColors.textTertiary,
                            onPressed: () => _removeRow(index),
                            padding: EdgeInsets.zero,
                            splashRadius: 14,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _CompactField({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _EditorRow {
  final TextEditingController keyController;
  final TextEditingController valueController;
  bool enabled;

  _EditorRow({
    required this.keyController,
    required this.valueController,
    this.enabled = true,
  });

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
