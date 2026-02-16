import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class UrlBar extends StatelessWidget {
  final TextEditingController controller;
  final String method;
  final ValueChanged<String> onMethodChanged;
  final bool isLoading;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const UrlBar({
    super.key,
    required this.controller,
    required this.method,
    required this.onMethodChanged,
    required this.isLoading,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── URL Field with Method Dropdown ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Method Dropdown
                _MethodDropdown(
                  method: method,
                  onChanged: onMethodChanged,
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.border,
                ),

                // URL Input
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSend(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/api...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Full Width Send Button ──
          _SendButton(
            isLoading: isLoading,
            onTap: onSend,
          ),
        ],
      ),
    );
  }
}

class _MethodDropdown extends StatelessWidget {
  final String method;
  final ValueChanged<String> onChanged;

  const _MethodDropdown({
    required this.method,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final methodColor = AppColors.getMethodColor(method);
    final methods = [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS'
    ];

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: method,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: AppColors.surfaceElevated,
            elevation: 4,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            items: methods.map((m) {
              final color = AppColors.getMethodColor(m);
              return DropdownMenuItem(
                value: m,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: m == method ? color.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return methods.map((m) {
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    m,
                    style: TextStyle(
                      color: methodColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surfaceLight;
            }
            return null; // Defer to flexible background
          }),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading ? null : AppColors.sendButtonGradient,
            color: isLoading ? AppColors.surfaceLight : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textTertiary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Send Request',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
