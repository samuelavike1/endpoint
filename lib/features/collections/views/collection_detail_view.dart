import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/collection_service.dart';
import '../providers/collection_provider.dart';
import '../../home/providers/workspace_provider.dart';
import '../../home/providers/request_provider.dart';
import '../../home/widgets/key_value_editor.dart';
import '../../home/widgets/auth_editor.dart';

class CollectionDetailView extends ConsumerStatefulWidget {
  final String collectionId;
  final VoidCallback? onRequestTapped;

  const CollectionDetailView({
    super.key,
    required this.collectionId,
    this.onRequestTapped,
  });

  @override
  ConsumerState<CollectionDetailView> createState() =>
      _CollectionDetailViewState();
}

class _CollectionDetailViewState extends ConsumerState<CollectionDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Settings controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _baseUrlController;

  static const _colorPalette = [
    Color(0xFF6C63FF),
    Color(0xFF4FC3F7),
    Color(0xFF66BB6A),
    Color(0xFFFFB74D),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _baseUrlController = TextEditingController();
    _loadControllersFromCollection();
  }

  void _loadControllersFromCollection() {
    final collection = ref
        .read(collectionProvider.notifier)
        .getCollection(widget.collectionId);
    if (collection != null) {
      _nameController.text = collection.name;
      _descController.text = collection.description;
      _baseUrlController.text = collection.baseUrl;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionProvider);
    final collection = collectionState.collections
        .where((c) => c.id == widget.collectionId)
        .firstOrNull;

    if (collection == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Collection not found',
            style: GoogleFonts.inter(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final color = _colorPalette[collection.colorIndex % _colorPalette.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            _buildTopBar(collection, color),

            // ─── Tabs: Requests / Settings ───
            _buildTabBar(),

            // ─── Tab Content ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsTab(collection, color),
                  _buildSettingsTab(collection, color),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? _buildFAB(collection)
          : null,
    );
  }

  // ─── Top Bar ───

  Widget _buildTopBar(Collection collection, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),

          // Folder badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.folder_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 10),

          // Title + request count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  collection.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (collection.description.isNotEmpty)
                  Text(
                    collection.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // More
          _buildIconBtn(Icons.more_vert_rounded, () {
            _showCollectionActionSheet(collection);
          }),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  // ─── Tab Bar ───

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}), // Rebuild for FAB toggle
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textTertiary,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Requests', height: 38),
          Tab(text: 'Settings', height: 38),
        ],
      ),
    );
  }

  // ─── Requests Tab ───

  Widget _buildRequestsTab(Collection collection, Color color) {
    if (collection.requests.isEmpty) {
      return _buildEmptyRequestsState(color);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: collection.requests.length,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.selectionClick();
        ref
            .read(collectionProvider.notifier)
            .reorderRequests(collection.id, oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          color: Colors.transparent,
          shadowColor: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final request = collection.requests[index];
        return _buildRequestCard(
          key: ValueKey(request.id),
          collection: collection,
          request: request,
          index: index,
          color: color,
        );
      },
    );
  }

  Widget _buildEmptyRequestsState(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 28,
              color: color.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Requests Yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add requests to organize your API calls',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _addBlankRequest(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Add Request',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required Key key,
    required Collection collection,
    required SavedRequest request,
    required int index,
    required Color color,
  }) {
    final methodColor = AppColors.getMethodColor(request.method);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openRequest(request, collection),
          onLongPress: () => _showRequestActions(collection, request),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Method badge
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      request.method,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: methodColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + URL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (request.url.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          request.url,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (request.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          request.description,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textTertiary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Settings Tab ───

  Widget _buildSettingsTab(Collection collection, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name ──
          _SectionHeader(title: 'COLLECTION NAME'),
          const SizedBox(height: 6),
          _SettingsTextField(
            controller: _nameController,
            hint: 'Collection name',
            onChanged: (v) {
              ref
                  .read(collectionProvider.notifier)
                  .updateCollectionConfig(collectionId: collection.id, name: v);
            },
          ),

          const SizedBox(height: 20),

          // ── Description ──
          _SectionHeader(title: 'DESCRIPTION'),
          const SizedBox(height: 6),
          _SettingsTextField(
            controller: _descController,
            hint: 'Describe the purpose of this collection...',
            maxLines: 3,
            onChanged: (v) {
              ref
                  .read(collectionProvider.notifier)
                  .updateCollectionConfig(
                    collectionId: collection.id,
                    description: v,
                  );
            },
          ),

          const SizedBox(height: 20),

          // ── Base URL ──
          _SectionHeader(title: 'BASE URL'),
          const SizedBox(height: 4),
          Text(
            'Prepended to request URLs. Use {{variables}} for environments.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          _SettingsTextField(
            controller: _baseUrlController,
            hint: 'https://api.example.com/v1',
            mono: true,
            onChanged: (v) {
              ref
                  .read(collectionProvider.notifier)
                  .updateCollectionConfig(
                    collectionId: collection.id,
                    baseUrl: v,
                  );
            },
          ),

          const SizedBox(height: 24),

          // ── Variables ──
          _buildVariablesSection(collection),

          const SizedBox(height: 24),

          // ── Shared Headers ──
          _buildSharedHeadersSection(collection),

          const SizedBox(height: 24),

          // ── Shared Auth ──
          _buildSharedAuthSection(collection),

          const SizedBox(height: 24),

          // ── Color ──
          _SectionHeader(title: 'COLOR'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_colorPalette.length, (i) {
              final isSelected = collection.colorIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(collectionProvider.notifier)
                      .updateCollectionConfig(
                        collectionId: collection.id,
                        colorIndex: i,
                      );
                },
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
                              color: _colorPalette[i].withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // ── Info ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Requests',
                  value: '${collection.requests.length}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Created',
                  value: _formatDate(collection.createdAt),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Last Modified',
                  value: _formatDate(collection.updatedAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Danger Zone ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DangerButton(
                        icon: Icons.copy_rounded,
                        label: 'Duplicate',
                        onTap: () {
                          ref
                              .read(collectionProvider.notifier)
                              .duplicateCollection(collection.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DangerButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        destructive: true,
                        onTap: () => _confirmDelete(collection),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Settings Sections ───

  Widget _buildVariablesSection(Collection collection) {
    // Convert Map<String, String> to List<KeyValuePair>
    final initialPairs = collection.variables.entries
        .map((e) => KeyValuePair(key: e.key, value: e.value))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: KeyValueEditor(
        title: 'VARIABLES',
        keyHint: 'Variable',
        valueHint: 'Value',
        initialPairs: initialPairs,
        onChanged: (pairs) {
          final variables = {
            for (var p in pairs)
              if (p.key.isNotEmpty) p.key: p.value,
          };
          ref
              .read(collectionProvider.notifier)
              .updateVariables(
                collectionId: collection.id,
                variables: variables,
              );
        },
      ),
    );
  }

  Widget _buildSharedHeadersSection(Collection collection) {
    List<KeyValuePair> initialPairs = [];
    if (collection.sharedHeadersJson != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(
          collection.sharedHeadersJson!,
        );
        initialPairs = parsed.entries
            .map((e) => KeyValuePair(key: e.key, value: e.value.toString()))
            .toList();
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: KeyValueEditor(
        title: 'SHARED HEADERS',
        keyHint: 'Header',
        valueHint: 'Value',
        initialPairs: initialPairs,
        onChanged: (pairs) {
          final headersMap = {
            for (var p in pairs)
              if (p.key.isNotEmpty) p.key: p.value,
          };
          ref
              .read(collectionProvider.notifier)
              .updateCollectionConfig(
                collectionId: collection.id,
                sharedHeadersJson: jsonEncode(headersMap),
              );
        },
      ),
    );
  }

  Widget _buildSharedAuthSection(Collection collection) {
    AuthConfig? initialAuth;
    if (collection.sharedAuthJson != null) {
      try {
        initialAuth = AuthConfig.fromJson(
          jsonDecode(collection.sharedAuthJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  'SHARED AUTHORIZATION',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          AuthEditor(
            auth: initialAuth ?? const AuthConfig(),
            onChanged: (auth) {
              ref
                  .read(collectionProvider.notifier)
                  .updateCollectionConfig(
                    collectionId: collection.id,
                    sharedAuthJson: jsonEncode(auth.toJson()),
                  );
            },
          ),
        ],
      ),
    );
  }

  // ─── FAB ───

  Widget _buildFAB(Collection collection) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddRequestOptions(collection),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      label: Text(
        'Add Request',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
    );
  }

  // ─── Actions ───

  void _addBlankRequest() {
    ref.read(collectionProvider.notifier).addBlankRequest(widget.collectionId);
  }

  void _openRequest(SavedRequest request, Collection collection) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(workspaceProvider.notifier);

    // ── Parse shared headers from collection ──
    List<KeyValuePair> sharedHeaders = [];
    if (collection.sharedHeadersJson != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(
          collection.sharedHeadersJson!,
        );
        sharedHeaders = parsed.entries
            .map((e) => KeyValuePair(key: e.key, value: e.value.toString()))
            .toList();
      } catch (_) {}
    }

    // ── Parse request headers ──
    List<KeyValuePair> headerPairs = [];
    if (request.headersJson != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(request.headersJson!);
        headerPairs = parsed.entries
            .map((e) => KeyValuePair(key: e.key, value: e.value.toString()))
            .toList();
      } catch (_) {}
    }

    // Merge: shared headers first, then request headers (request overrides)
    final allHeaders = <String, KeyValuePair>{};
    for (final h in sharedHeaders) {
      allHeaders[h.key.toLowerCase()] = h;
    }
    for (final h in headerPairs) {
      allHeaders[h.key.toLowerCase()] = h;
    }
    final mergedHeaders = allHeaders.values.toList().isNotEmpty
        ? allHeaders.values.toList()
        : null;

    // ── Parse request params ──
    List<KeyValuePair> paramPairs = [];
    if (request.paramsJson != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(request.paramsJson!);
        paramPairs = parsed.entries
            .map((e) => KeyValuePair(key: e.key, value: e.value.toString()))
            .toList();
      } catch (_) {}
    }

    // ── Auth: use request auth, fallback to shared collection auth ──
    AuthConfig auth = const AuthConfig();
    if (request.authJson != null) {
      try {
        auth = AuthConfig.fromJson(
          jsonDecode(request.authJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    if (auth.type == AuthType.none && collection.sharedAuthJson != null) {
      try {
        auth = AuthConfig.fromJson(
          jsonDecode(collection.sharedAuthJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    // ── Build URL with base URL ──
    String url = request.url;
    if (collection.baseUrl.isNotEmpty &&
        url.isNotEmpty &&
        !url.startsWith('http')) {
      final base = collection.baseUrl.endsWith('/')
          ? collection.baseUrl.substring(0, collection.baseUrl.length - 1)
          : collection.baseUrl;
      final path = url.startsWith('/') ? url : '/$url';
      url = '$base$path';
    }

    // ── Substitute variables in everything ──
    url = collection.substituteVariables(url);
    final body = collection.substituteVariables(request.body ?? '');

    // Substitute in headers
    final substitutedHeaders = (mergedHeaders ?? defaultHeaders)
        .map(
          (h) => KeyValuePair(
            key: collection.substituteVariables(h.key),
            value: collection.substituteVariables(h.value),
          ),
        )
        .toList();

    // Substitute in params
    final substitutedParams = paramPairs
        .map(
          (p) => KeyValuePair(
            key: collection.substituteVariables(p.key),
            value: collection.substituteVariables(p.value),
          ),
        )
        .toList();

    // Substitute in auth fields
    auth = AuthConfig(
      type: auth.type,
      token: collection.substituteVariables(auth.token),
      username: collection.substituteVariables(auth.username),
      password: collection.substituteVariables(auth.password),
      apiKeyName: collection.substituteVariables(auth.apiKeyName),
      apiKeyValue: collection.substituteVariables(auth.apiKeyValue),
      apiKeyInHeader: auth.apiKeyInHeader,
    );

    notifier.loadSavedRequest(
      url: url,
      method: request.method,
      headers: substitutedHeaders,
      params: substitutedParams,
      body: body,
      auth: auth,
    );

    Navigator.pop(context);
    widget.onRequestTapped?.call();
  }

  void _showAddRequestOptions(Collection collection) {
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
            _buildSheetHandle(),
            Text(
              'Add Request',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'Blank Request',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Create a new empty request',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _addBlankRequest();
              },
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.content_paste_go_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              title: Text(
                'Save Current Request',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Save the active workspace request here',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _saveCurrentRequest(collection);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _saveCurrentRequest(Collection collection) {
    final workspace = ref.read(workspaceProvider);
    final activeTab = workspace.activeTab;
    if (activeTab == null) return;

    final nameController = TextEditingController(
      text: activeTab.displayName == 'New Request' ? '' : activeTab.displayName,
    );
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Save Request',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogTextField(
              controller: nameController,
              hint: 'Request name',
              autofocus: true,
            ),
            const SizedBox(height: 10),
            _DialogTextField(
              controller: descController,
              hint: 'Description (optional)',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(collectionProvider.notifier)
                  .saveCurrentRequest(
                    collectionId: collection.id,
                    requestState: activeTab.state,
                    name: nameController.text.trim().isNotEmpty
                        ? nameController.text.trim()
                        : null,
                    description: descController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestActions(Collection collection, SavedRequest request) {
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
            _buildSheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getMethodColor(
                        request.method,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      request.method,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getMethodColor(request.method),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SheetAction(
              icon: Icons.open_in_new_rounded,
              label: 'Open in Workspace',
              onTap: () {
                Navigator.pop(ctx);
                _openRequest(request, collection);
              },
            ),
            _SheetAction(
              icon: Icons.edit_rounded,
              label: 'Rename',
              onTap: () {
                Navigator.pop(ctx);
                _renameRequest(collection, request);
              },
            ),
            _SheetAction(
              icon: Icons.copy_rounded,
              label: 'Duplicate',
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(collectionProvider.notifier)
                    .duplicateRequest(collection.id, request.id);
              },
            ),
            _SheetAction(
              icon: Icons.delete_outline_rounded,
              label: 'Remove',
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(collectionProvider.notifier)
                    .removeRequest(collection.id, request.id);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _renameRequest(Collection collection, SavedRequest request) {
    final nameCtrl = TextEditingController(text: request.name);
    final descCtrl = TextEditingController(text: request.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Request',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogTextField(
              controller: nameCtrl,
              hint: 'Request name',
              autofocus: true,
            ),
            const SizedBox(height: 10),
            _DialogTextField(
              controller: descCtrl,
              hint: 'Description (optional)',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(collectionProvider.notifier)
                  .updateRequest(
                    collectionId: collection.id,
                    updatedRequest: request.copyWith(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    ),
                  );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectionActionSheet(Collection collection) {
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
            _buildSheetHandle(),
            _SheetAction(
              icon: Icons.copy_rounded,
              label: 'Duplicate Collection',
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(collectionProvider.notifier)
                    .duplicateCollection(collection.id);
                Navigator.pop(context);
              },
            ),
            _SheetAction(
              icon: Icons.download_rounded,
              label: 'Export as JSON',
              onTap: () {
                Navigator.pop(ctx);
                _exportCollection(collection);
              },
            ),
            _SheetAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Collection',
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(collection);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Collection collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Collection?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete "${collection.name}" and all ${collection.requests.length} requests inside it.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(collectionProvider.notifier)
                  .deleteCollection(collection.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportCollection(Collection collection) {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(collection.toJson());
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Collection JSON copied to clipboard',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Helpers ───

  Widget _buildSheetHandle() {
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ──────────────── Reusable sub-widgets ────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool mono;
  final ValueChanged<String> onChanged;

  const _SettingsTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.mono = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
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
        fillColor: AppColors.surface,
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

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int maxLines;

  const _DialogTextField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: destructive
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: destructive ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: destructive ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: destructive ? AppColors.error : AppColors.textPrimary,
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: destructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
