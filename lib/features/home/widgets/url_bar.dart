import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class UrlBar extends StatelessWidget {
  final TextEditingController controller;
  final String method;
  final bool isLoading;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const UrlBar({
    super.key,
    required this.controller,
    required this.method,
    required this.isLoading,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final methodColor = AppColors.getMethodColor(method);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Method badge
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: methodColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                method,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: methodColor,
                  letterSpacing: 0.5,
                ),
              ),
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
                  hintText: 'Enter URL...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),

            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _SendButton(
                isLoading: isLoading,
                onTap: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({required this.isLoading, required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) {
          setState(() => _isPressed = true);
          _controller.forward();
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: widget.isLoading ? null : AppColors.sendButtonGradient,
                color: widget.isLoading ? AppColors.surfaceLight : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: !widget.isLoading && !_isPressed
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
