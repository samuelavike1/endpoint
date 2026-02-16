import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/collection_service.dart';
import '../providers/collection_provider.dart';
import 'collection_detail_view.dart';

class CollectionView extends ConsumerStatefulWidget {
  final VoidCallback? onRequestTapped;

  const CollectionView({super.key, this.onRequestTapped});

  @override
  ConsumerState<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends ConsumerState<CollectionView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _colorPalette = [
    Color(0xFF6C63FF),
    Color(0xFF4FC3F7),
    Color(0xFF66BB6A),
    Color(0xFFFFB74D),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionProvider);
    final collections = collectionState.collections.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.requests.any(
            (r) =>
                r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.url.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildStats(collectionState),
            Expanded(
              child: collectionState.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : collections.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: collections.length,
                      itemBuilder: (context, index) =>
                          _buildCollectionCard(collections[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCollectionDialog(),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Icon(
          Icons.create_new_folder_rounded,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          Text(
            'Collections',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(collectionProvider.notifier).loadCollections();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search collections & requests...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStats(CollectionState state) {
    final totalRequests = state.collections.fold<int>(
      0,
      (sum, c) => sum + c.requests.length,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.folder_rounded,
            value: '${state.collections.length}',
            label: 'collection${state.collections.length == 1 ? '' : 's'}',
          ),
          const SizedBox(width: 16),
          _StatChip(
            icon: Icons.description_outlined,
            value: '$totalRequests',
            label: 'request${totalRequests == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No Results' : 'No Collections Yet',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Organize your API requests\ninto collections for quick access',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _showCreateCollectionDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Collection',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionCard(Collection collection) {
    final color = _colorPalette[collection.colorIndex % _colorPalette.length];
    final requestCount = collection.requests.length;

    // Show first 3 methods as preview dots
    final previewMethods = collection.requests
        .take(4)
        .map((r) => r.method)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectionDetailView(
                  collectionId: collection.id,
                  onRequestTapped: widget.onRequestTapped,
                ),
              ),
            );
          },
          onLongPress: () => _showCollectionMenu(collection),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Collection folder icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder_rounded, size: 24, color: color),
                ),
                const SizedBox(width: 14),

                // Name + details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (collection.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          collection.description,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Request count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$requestCount request${requestCount == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: color.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          if (collection.baseUrl.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  collection.baseUrl,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8,
                                    color: AppColors.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          // Method preview dots
                          if (previewMethods.isNotEmpty) ...[
                            const Spacer(),
                            ...previewMethods.map(
                              (m) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(left: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.getMethodColor(m),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Dialogs ───

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final baseUrlController = TextEditingController();
    int selectedColor = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'New Collection',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Organize related API requests together',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),

              const SizedBox(height: 20),

              // Name
              _SheetLabel(text: 'NAME'),
              const SizedBox(height: 6),
              _SheetTextField(
                controller: nameController,
                hint: 'e.g. User API, Payment Service',
                autofocus: true,
              ),

              const SizedBox(height: 16),

              // Description
              _SheetLabel(text: 'DESCRIPTION'),
              const SizedBox(height: 6),
              _SheetTextField(
                controller: descController,
                hint: 'What does this collection contain?',
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Base URL
              _SheetLabel(text: 'BASE URL (OPTIONAL)'),
              const SizedBox(height: 6),
              _SheetTextField(
                controller: baseUrlController,
                hint: 'https://api.example.com/v1',
                mono: true,
              ),

              const SizedBox(height: 16),

              // Color
              _SheetLabel(text: 'COLOR'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_colorPalette.length, (i) {
                  final isSelected = selectedColor == i;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _colorPalette[i],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _colorPalette[i].withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    ref
                        .read(collectionProvider.notifier)
                        .createCollection(
                          name: name,
                          colorIndex: selectedColor,
                          description: descController.text.trim(),
                          baseUrl: baseUrlController.text.trim(),
                        );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create Collection',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollectionMenu(Collection collection) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                collection.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
              title: Text(
                'Open',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectionDetailView(
                      collectionId: collection.id,
                      onRequestTapped: widget.onRequestTapped,
                    ),
                  ),
                );
              },
              dense: true,
            ),
            ListTile(
              leading: Icon(
                Icons.copy_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
              title: Text(
                'Duplicate',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(collectionProvider.notifier)
                    .duplicateCollection(collection.id);
              },
              dense: true,
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.error,
              ),
              title: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(collectionProvider.notifier)
                    .deleteCollection(collection.id);
              },
              dense: true,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ──────────────── Helper Widgets ────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int maxLines;
  final bool mono;

  const _SheetTextField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.maxLines = 1,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      style: mono
          ? GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: AppColors.textPrimary,
            )
          : GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
