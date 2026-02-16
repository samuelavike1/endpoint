import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/request_provider.dart';
import '../widgets/method_selector.dart';
import '../widgets/url_bar.dart';
import '../widgets/key_value_editor.dart';
import '../widgets/body_editor.dart';
import '../widgets/response_panel.dart';

class RequestView extends ConsumerStatefulWidget {
  const RequestView({super.key});

  @override
  ConsumerState<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends ConsumerState<RequestView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _responseExpanded = true; // Whether the response panel is expanded

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(requestProvider);
    final notifier = ref.read(requestProvider.notifier);
    final hasResponse = requestState.response != null;

    // Auto-expand response when a new one arrives
    ref.listen<RequestState>(requestProvider, (prev, next) {
      if (next.response != null && prev?.response != next.response) {
        setState(() => _responseExpanded = true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Header ──
            _buildHeader(hasResponse),

            const SizedBox(height: 12),

            // ── Method Selector ──
            MethodSelector(
              selectedMethod: requestState.method,
              onMethodChanged: (method) {
                HapticFeedback.selectionClick();
                notifier.updateMethod(method);
              },
            ),

            const SizedBox(height: 12),

            // ── URL Bar ──
            UrlBar(
              controller: _urlController,
              method: requestState.method,
              isLoading: requestState.isLoading,
              onChanged: notifier.updateUrl,
              onSend: () {
                HapticFeedback.mediumImpact();
                notifier.sendRequest().then((_) {
                  ref.read(historyProvider.notifier).loadHistory();
                });
              },
            ),

            const SizedBox(height: 8),

            // ── Request Config Tabs ──
            _buildConfigTabs(),

            // ── Main content area: config + response ──
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

  Widget _buildHeader(bool hasResponse) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.api_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Endpoint',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'API Client',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Clear/new request button
          if (hasResponse)
            _HeaderAction(
              icon: Icons.add_rounded,
              onTap: () {
                setState(() => _responseExpanded = false);
                ref.read(requestProvider.notifier).clearResponse();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConfigTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Params', height: 40),
          Tab(text: 'Headers', height: 40),
          Tab(text: 'Body', height: 40),
        ],
      ),
    );
  }

  Widget _buildTabContent(RequestState state, RequestNotifier notifier) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Params tab
        SingleChildScrollView(
          child: KeyValueEditor(
            title: 'Query Parameters',
            keyHint: 'Parameter',
            valueHint: 'Value',
            initialPairs: state.params,
            onChanged: notifier.updateParams,
          ),
        ),

        // Headers tab
        SingleChildScrollView(
          child: KeyValueEditor(
            title: 'Request Headers',
            keyHint: 'Header',
            valueHint: 'Value',
            initialPairs: state.headers,
            onChanged: notifier.updateHeaders,
          ),
        ),

        // Body tab
        BodyEditor(
          controller: _bodyController,
          onChanged: notifier.updateBody,
          onPrettify: notifier.prettifyBody,
        ),
      ],
    );
  }

  /// Layout when we have a response: config tabs on top + collapsible response below
  Widget _buildWithResponse(RequestState state, RequestNotifier notifier) {
    return Column(
      children: [
        // ── Request config section ──
        // When response is collapsed, config gets most space; when expanded, it gets less
        Expanded(
          flex: _responseExpanded ? 0 : 1,
          child: _responseExpanded
              ? const SizedBox.shrink()
              : _buildTabContent(state, notifier),
        ),

        // ── Response toggle bar ──
        _buildResponseToggle(),

        // ── Response panel ──
        if (_responseExpanded)
          Expanded(
            flex: 1,
            child: ResponsePanel(response: state.response!),
          ),
      ],
    );
  }

  /// A tappable bar to toggle the response panel
  Widget _buildResponseToggle() {
    final response = ref.read(requestProvider).response;
    if (response == null) return const SizedBox.shrink();

    final statusColor = _getStatusColor(response.statusCode);

    return GestureDetector(
      onTap: () => setState(() => _responseExpanded = !_responseExpanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Response label
            Text(
              'RESPONSE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),

            // Status code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                response.statusCode == 0
                    ? 'ERR'
                    : '${response.statusCode}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Duration pill
            Text(
              '${response.durationMs}ms',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),

            const Spacer(),

            // Collapse/expand hint
            Text(
              _responseExpanded ? 'Collapse' : 'Expand',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _responseExpanded ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
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

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}
