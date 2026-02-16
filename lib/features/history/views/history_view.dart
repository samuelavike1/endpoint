import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/history_service.dart';
import '../../home/providers/request_provider.dart';

class HistoryView extends ConsumerStatefulWidget {
  final VoidCallback? onItemTapped;

  const HistoryView({super.key, this.onItemTapped});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final filteredItems = _searchQuery.isEmpty
        ? historyState.items
        : historyState.items
            .where((item) =>
                item.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.method.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Search bar
            _buildSearchBar(),

            const SizedBox(height: 8),

            // History list
            Expanded(
              child: historyState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(filteredItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '${historyState.items.length} requests',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (historyState.items.isNotEmpty)
            _ActionChip(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear',
              onTap: () => _showClearDialog(context),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search requests...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textTertiary, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No history yet' : 'No results found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Your API requests will appear here'
                : 'Try a different search term',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> items) {
    // Group items by date
    final grouped = <String, List<HistoryItem>>{};
    for (final item in items) {
      final dateKey = _formatDateKey(item.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(historyProvider.notifier).loadHistory(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: grouped.length,
        itemBuilder: (context, groupIndex) {
          final dateKey = grouped.keys.elementAt(groupIndex);
          final groupItems = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Text(
                  dateKey,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Items
              ...groupItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Animate(
                  effects: [
                    FadeEffect(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: index * 50),
                    ),
                    SlideEffect(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: index * 50),
                    ),
                  ],
                  child: _HistoryCard(
                    item: item,
                    onTap: () {
                      ref
                          .read(requestProvider.notifier)
                          .loadFromHistory(item);
                      widget.onItemTapped?.call();
                    },
                    onDelete: () {
                      ref
                          .read(historyProvider.notifier)
                          .deleteItem(item.id);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear History',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        content: Text(
          'This will delete all request history. This action cannot be undone.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: Text('Clear',
                style: GoogleFonts.inter(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final methodColor = AppColors.getMethodColor(item.method);
    final statusColor = item.statusCode == 0
        ? AppColors.error
        : item.isSuccess
            ? AppColors.success
            : item.statusCode >= 400
                ? AppColors.error
                : AppColors.warning;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Method badge
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    item.method,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: methodColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // URL & metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayUrl,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.statusCode == 0 ? 'ERR' : '${item.statusCode}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Duration
                        Icon(Icons.timer_outlined,
                            size: 10, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(
                          '${item.durationMs}ms',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Time
                        Text(
                          _formatTime(item.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
