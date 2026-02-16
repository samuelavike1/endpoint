import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class MethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const MethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  static const List<String> _methods = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _methods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final method = _methods[index];
          final isSelected = selectedMethod == method;
          final color = AppColors.getMethodColor(method);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onMethodChanged(method);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  method,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
