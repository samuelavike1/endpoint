import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import 'json_syntax_highlight.dart';

class ResponsePanel extends StatefulWidget {
  final ApiResponse response;

  const ResponsePanel({super.key, required this.response});

  @override
  State<ResponsePanel> createState() => _ResponsePanelState();
}

class _ResponsePanelState extends State<ResponsePanel> {
  int _activeTab = 0; // 0=Body, 1=Headers, 2=Info

  Color get _statusColor {
    final code = widget.response.statusCode;
    if (code == 0) return AppColors.error;
    if (code >= 200 && code < 300) return AppColors.success;
    if (code >= 300 && code < 400) return AppColors.info;
    if (code >= 400 && code < 500) return AppColors.warning;
    return AppColors.error;
  }

  String get _statusLabel {
    final code = widget.response.statusCode;
    if (code == 0) return 'ERR';
    return '$code';
  }

  String get _sizeString {
    final bytes = widget.response.sizeBytes;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Tab bar
          _buildTabBar(),

          // Content
          Expanded(child: _buildContent()),

          // Copy bar at the bottom
          _buildCopyBar(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Body', 'Headers', 'Info'];
    final icons = [
      Icons.code_rounded,
      Icons.list_alt_rounded,
      Icons.info_outline_rounded,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? Border.all(color: AppColors.border)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      size: 13,
                      color: isActive ? AppColors.primary : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tabs[i],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    if (i == 1) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.response.responseHeaders.length}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case 0:
        return _buildBodyTab();
      case 1:
        return _buildHeadersTab();
      case 2:
        return _buildInfoTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBodyTab() {
    final body = widget.response.body;

    if (body.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off_rounded,
                size: 28,
                color: AppColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'No response body',
              style:
                  GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Check if it looks like JSON
    final trimmed = body.trimLeft();
    final isJson = trimmed.startsWith('{') || trimmed.startsWith('[');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: isJson
          ? JsonSyntaxHighlight(source: body, fontSize: 12)
          : SelectableText(
              body,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
    );
  }

  Widget _buildHeadersTab() {
    final headers = widget.response.responseHeaders;
    if (headers.isEmpty) {
      return Center(
        child: Text(
          'No response headers',
          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: headers.length,
      itemBuilder: (context, index) {
        final key = headers.keys.elementAt(index);
        final value = headers[key].toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: index.isEven
                ? AppColors.background.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: SelectableText(
                  key,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _InfoCard(
            items: [
              _InfoItem(
                  label: 'Status',
                  value: _statusLabel,
                  color: _statusColor),
              _InfoItem(
                  label: 'Time',
                  value: '${widget.response.durationMs}ms'),
            ],
          ),
          const SizedBox(height: 8),
          _InfoCard(
            items: [
              _InfoItem(label: 'Size', value: _sizeString),
              _InfoItem(
                label: 'Headers',
                value: '${widget.response.responseHeaders.length}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoCard(
            items: [
              _InfoItem(
                label: 'Body Lines',
                value: '${widget.response.body.split('\n').length}',
              ),
              _InfoItem(
                label: 'Message',
                value: widget.response.statusMessage.isNotEmpty
                    ? widget.response.statusMessage
                    : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.background,
      ),
      child: Row(
        children: [
          Icon(Icons.straighten_outlined,
              size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            _sizeString,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.timer_outlined, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            '${widget.response.durationMs}ms',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          _CopyButton(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.response.body));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Copied!', style: GoogleFonts.inter(fontSize: 13)),
                    backgroundColor: AppColors.surfaceElevated,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Small helper widgets ───

class _CopyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CopyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_rounded,
                  size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Copy',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.color ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final Color? color;
  const _InfoItem({required this.label, required this.value, this.color});
}
