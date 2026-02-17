import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/request_provider.dart';
import '../widgets/url_bar.dart';
import '../widgets/key_value_editor.dart';
import '../widgets/body_editor.dart';
import '../widgets/auth_editor.dart';
import '../widgets/response_panel.dart';
import '../widgets/json_syntax_highlight.dart';
import '../../collections/providers/collection_provider.dart';
import '../../../core/data/collection_service.dart';

class RequestView extends ConsumerStatefulWidget {
  const RequestView({super.key});

  @override
  ConsumerState<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends ConsumerState<RequestView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final JsonSyntaxTextController _bodyController = JsonSyntaxTextController();
  bool _responseExpanded = true;
  String? _lastSyncedTabId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// Sync text controllers when active tab changes
  void _syncControllers(RequestTab? activeTab) {
    if (activeTab == null) return;
    if (_lastSyncedTabId != activeTab.id) {
      _lastSyncedTabId = activeTab.id;
      // Update URL controller
      if (_urlController.text != activeTab.state.url) {
        _urlController.text = activeTab.state.url;
      }
      // Update body controller
      if (_bodyController.text != activeTab.state.body) {
        _bodyController.text = activeTab.state.body;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final activeTab = workspace.activeTab;

    // Sync controllers when switching tabs
    _syncControllers(activeTab);

    // Auto-expand response when a new one arrives
    ref.listen<WorkspaceState>(workspaceProvider, (prev, next) {
      final prevResp = prev?.activeTab?.state.response;
      final nextResp = next.activeTab?.state.response;
      if (nextResp != null && prevResp != nextResp) {
        setState(() => _responseExpanded = true);
      }
    });

    if (activeTab == null) return const SizedBox();
    final requestState = activeTab.state;
    final hasResponse = requestState.response != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Header ──
            _buildHeader(hasResponse, notifier),

            // ── Request Tabs Bar ──
            _buildRequestTabs(workspace, notifier),

            const SizedBox(height: 8),

            // ── URL Bar ──
            UrlBar(
              controller: _urlController,
              method: requestState.method,
              onMethodChanged: (method) {
                HapticFeedback.selectionClick();
                notifier.updateMethod(method);
              },
              isLoading: requestState.isLoading,
              onChanged: notifier.updateUrl,
              onSend: () {
                HapticFeedback.mediumImpact();
                notifier.sendRequest().then((_) {
                  ref.read(historyProvider.notifier).loadHistory();
                });
              },
            ),

            const SizedBox(height: 6),

            // ── Config Tabs ──
            _buildConfigTabs(),

            // ── Main content area ──
            Expanded(
              child: hasResponse
                  ? _buildWithResponse(requestState, notifier)
                  : _buildTabContent(requestState, notifier),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Header with theme toggle ───

  Widget _buildHeader(bool hasResponse, WorkspaceNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.api_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Endpoint',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),

          // Theme toggle
          _ThemeToggle(),

          const SizedBox(width: 6),

          // Save to collection button
          _HeaderAction(
            icon: Icons.bookmark_add_outlined,
            onTap: () {
              final workspace = ref.read(workspaceProvider);
              final activeTab = workspace.activeTab;
              if (activeTab != null) {
                _showSaveToCollectionDialog(activeTab.state);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Request Tabs (horizontal scrollable) ───

  Widget _buildRequestTabs(
    WorkspaceState workspace,
    WorkspaceNotifier notifier,
  ) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Scrollable tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: workspace.tabs.length,
              itemBuilder: (context, index) {
                final tab = workspace.tabs[index];
                final isActive = index == workspace.activeIndex;
                final methodColor = AppColors.getMethodColor(tab.state.method);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.switchTab(index);
                    // Reset response expansion when switching tabs
                    setState(() {
                      _responseExpanded = tab.state.response != null;
                    });
                  },
                  onLongPress: () => _showTabMenu(context, index, notifier),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.surface
                          : AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? methodColor.withValues(alpha: 0.4)
                            : AppColors.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Method dot
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: methodColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Method label
                        Text(
                          tab.state.method,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: methodColor,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Tab name
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            tab.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),

                        // Close button (only for active tab with more than 1 tab)
                        if (isActive && workspace.tabs.length > 1) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notifier.closeTab(index);
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add tab button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.addTab();
            },
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 16, left: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTabMenu(
    BuildContext context,
    int index,
    WorkspaceNotifier notifier,
  ) {
    final tab = ref.read(workspaceProvider).tabs[index];
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
                tab.displayName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MenuAction(
              icon: Icons.copy_rounded,
              label: 'Duplicate Tab',
              onTap: () {
                notifier.duplicateTab(index);
                Navigator.pop(ctx);
              },
            ),
            _MenuAction(
              icon: Icons.bookmark_add_rounded,
              label: 'Save to Collection',
              onTap: () {
                Navigator.pop(ctx);
                _showSaveToCollectionDialog(tab.state);
              },
            ),
            _MenuAction(
              icon: Icons.close_rounded,
              label: 'Close Tab',
              isDestructive: true,
              onTap: () {
                notifier.closeTab(index);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static final _colorPalette = [
    Color(0xFF818CF8), // Indigo 400
    Color(0xFF38BDF8), // Sky 400
    Color(0xFF4ADE80), // Green 400
    Color(0xFFFBBF24), // Amber 400
    Color(0xFFF87171), // Red 400
    Color(0xFFA78BFA), // Violet 400
  ];

  void _showSaveToCollectionDialog(RequestState requestState) {
    final collections = ref.read(collectionProvider).collections;

    if (collections.isEmpty) {
      _showQuickCreateAndSave(requestState);
      return;
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save to Collection',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...collections.map((c) {
              final color = _colorPalette[c.colorIndex % _colorPalette.length];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.folder_rounded, size: 20, color: color),
                ),
                title: Text(
                  c.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${c.requests.length} request${c.requests.length == 1 ? '' : 's'}${c.baseUrl.isNotEmpty ? ' · ${c.baseUrl}' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSaveNameDialog(requestState, c);
                },
                dense: true,
              );
            }),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.create_new_folder_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'New Collection',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showQuickCreateAndSave(requestState);
              },
              dense: true,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSaveNameDialog(RequestState requestState, Collection collection) {
    final nameController = TextEditingController(
      text: _deriveRequestName(requestState),
    );
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bookmark_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Save to ${collection.name}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REQUEST NAME',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Request name',
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
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'DESCRIPTION',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: descController,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Optional description',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
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
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Preview
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getMethodColor(
                        requestState.method,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      requestState.method,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getMethodColor(requestState.method),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requestState.url.isEmpty ? 'No URL' : requestState.url,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
              final name = nameController.text.trim();
              ref
                  .read(collectionProvider.notifier)
                  .saveCurrentRequest(
                    collectionId: collection.id,
                    requestState: requestState,
                    name: name.isNotEmpty ? name : null,
                    description: descController.text.trim(),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saved to ${collection.name}',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
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

  void _showQuickCreateAndSave(RequestState requestState) {
    final nameCtrl = TextEditingController();
    int selectedColor = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'New Collection',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a collection and save the current request.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Collection name',
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
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(_colorPalette.length, (i) {
                  final isSelected = selectedColor == i;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = i),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _colorPalette[i],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }),
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
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(collectionProvider.notifier)
                    .createCollection(name: name, colorIndex: selectedColor);
                final cols = ref.read(collectionProvider).collections;
                if (cols.isNotEmpty) {
                  ref
                      .read(collectionProvider.notifier)
                      .saveCurrentRequest(
                        collectionId: cols.last.id,
                        requestState: requestState,
                      );
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Collection created & request saved',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Create & Save',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _deriveRequestName(RequestState rs) {
    if (rs.url.isEmpty) return '${rs.method} Request';
    try {
      final uri = Uri.parse(
        rs.url.startsWith('http') ? rs.url : 'https://${rs.url}',
      );
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        return last.isEmpty ? uri.host : last;
      }
      return uri.host;
    } catch (_) {
      return rs.url.length > 30 ? '${rs.url.substring(0, 27)}...' : rs.url;
    }
  }

  // ─── Config Tabs (Params / Headers / Body) ───

  Widget _buildConfigTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
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
          Tab(text: 'Body', height: 38),
          Tab(text: 'Params', height: 38),
          Tab(text: 'Headers', height: 38),
          Tab(text: 'Auth', height: 38),
        ],
      ),
    );
  }

  Widget _buildTabContent(RequestState state, WorkspaceNotifier notifier) {
    return TabBarView(
      controller: _tabController,
      children: [
        BodyEditor(
          controller: _bodyController,
          onChanged: notifier.updateBody,
          onPrettify: () {
            final text = _bodyController.text;
            if (text.trim().isEmpty) return;
            try {
              final parsed = jsonDecode(text);
              final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
              _bodyController.text = pretty;
              notifier.updateBody(pretty);
            } catch (_) {}
          },
        ),
        SingleChildScrollView(
          child: KeyValueEditor(
            title: 'Query Parameters',
            keyHint: 'Parameter',
            valueHint: 'Value',
            initialPairs: state.params,
            onChanged: notifier.updateParams,
          ),
        ),
        SingleChildScrollView(
          child: KeyValueEditor(
            title: 'Request Headers',
            keyHint: 'Header',
            valueHint: 'Value',
            initialPairs: state.headers,
            onChanged: notifier.updateHeaders,
          ),
        ),
        AuthEditor(auth: state.auth, onChanged: notifier.updateAuth),
      ],
    );
  }

  // ─── Layout with response ───

  Widget _buildWithResponse(RequestState state, WorkspaceNotifier notifier) {
    return Column(
      children: [
        // Config section (visible when response collapsed)
        if (!_responseExpanded)
          Expanded(child: _buildTabContent(state, notifier)),

        // Response toggle bar
        _buildResponseToggle(state),

        // Response panel
        if (_responseExpanded)
          Expanded(child: ResponsePanel(response: state.response!)),
      ],
    );
  }

  Widget _buildResponseToggle(RequestState state) {
    final response = state.response;
    if (response == null) return const SizedBox.shrink();

    final statusColor = _getStatusColor(response.statusCode);

    return GestureDetector(
      onTap: () => setState(() => _responseExpanded = !_responseExpanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RESPONSE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                response.statusCode == 0 ? 'ERR' : '${response.statusCode}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${response.durationMs}ms',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              _responseExpanded ? 'Collapse' : 'Expand',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 3),
            AnimatedRotation(
              turns: _responseExpanded ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(int code) {
    if (code == 0) return AppColors.error;
    if (code >= 200 && code < 300) return AppColors.success;
    if (code >= 300 && code < 400) return AppColors.info;
    if (code >= 400 && code < 500) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Helper Widgets ───

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == AppThemeMode.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(themeProvider.notifier).toggle();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            size: 16,
            color: isDark ? AppColors.warning : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
