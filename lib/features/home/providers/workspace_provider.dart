import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/history_service.dart';
import 'request_provider.dart';

// ──────────────── Request Tab ────────────────
class RequestTab {
  final String id;
  final RequestState state;

  const RequestTab({required this.id, required this.state});

  /// Derive a display name from the URL or fallback
  String get displayName {
    if (state.url.isEmpty) return 'New Request';
    try {
      final uri = Uri.parse(
        state.url.startsWith('http') ? state.url : 'https://${state.url}',
      );
      // Show the last path segment or host
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.isNotEmpty) return '/${last.length > 20 ? '${last.substring(0, 17)}...' : last}';
      }
      return uri.host.length > 20 ? '${uri.host.substring(0, 17)}...' : uri.host;
    } catch (_) {
      return state.url.length > 20
          ? '${state.url.substring(0, 17)}...'
          : state.url;
    }
  }

  RequestTab copyWith({RequestState? state}) {
    return RequestTab(id: id, state: state ?? this.state);
  }
}

// ──────────────── Workspace State ────────────────
class WorkspaceState {
  final List<RequestTab> tabs;
  final int activeIndex;

  const WorkspaceState({
    this.tabs = const [],
    this.activeIndex = 0,
  });

  RequestTab? get activeTab =>
      tabs.isNotEmpty && activeIndex < tabs.length ? tabs[activeIndex] : null;

  WorkspaceState copyWith({List<RequestTab>? tabs, int? activeIndex}) {
    return WorkspaceState(
      tabs: tabs ?? this.tabs,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

// ──────────────── Workspace Notifier ────────────────
class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier()
      : super(WorkspaceState(
          tabs: [
            RequestTab(
              id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
              state: const RequestState(headers: defaultHeaders),
            ),
          ],
          activeIndex: 0,
        ));

  // ── Tab management ──

  void addTab() {
    final newTab = RequestTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      state: const RequestState(headers: defaultHeaders),
    );
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(tabs: newTabs, activeIndex: newTabs.length - 1);
  }

  void switchTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) {
      // Can't close the last tab — reset it instead
      final resetTab = RequestTab(
        id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
        state: const RequestState(headers: defaultHeaders),
      );
      state = WorkspaceState(tabs: [resetTab], activeIndex: 0);
      return;
    }

    final newTabs = [...state.tabs]..removeAt(index);
    int newActive = state.activeIndex;

    if (index <= newActive) {
      newActive = (newActive - 1).clamp(0, newTabs.length - 1);
    }

    state = state.copyWith(tabs: newTabs, activeIndex: newActive);
  }

  void duplicateTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    final original = state.tabs[index];
    final duplicate = RequestTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      state: original.state.copyWith(),
    );
    final newTabs = [...state.tabs]..insert(index + 1, duplicate);
    state = state.copyWith(tabs: newTabs, activeIndex: index + 1);
  }

  // ── Active tab operations ──

  void _updateActive(RequestState newState) {
    if (state.tabs.isEmpty) return;
    final newTabs = [...state.tabs];
    newTabs[state.activeIndex] =
        state.tabs[state.activeIndex].copyWith(state: newState);
    state = state.copyWith(tabs: newTabs);
  }

  RequestState get _active => state.activeTab!.state;

  void updateUrl(String url) => _updateActive(_active.copyWith(url: url));

  void updateMethod(String method) =>
      _updateActive(_active.copyWith(method: method));

  void updateBody(String body) => _updateActive(_active.copyWith(body: body));

  void updateHeaders(List<KeyValuePair> headers) =>
      _updateActive(_active.copyWith(headers: headers));

  void updateParams(List<KeyValuePair> params) =>
      _updateActive(_active.copyWith(params: params));

  void setActiveTabIndex(int index) =>
      _updateActive(_active.copyWith(activeTabIndex: index));

  void updateAuth(AuthConfig auth) =>
      _updateActive(_active.copyWith(auth: auth));

  void clearResponse() =>
      _updateActive(_active.copyWith(clearResponse: true, clearError: true));

  void prettifyBody() {
    if (_active.body.trim().isEmpty) return;
    try {
      final parsed = jsonDecode(_active.body);
      final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
      _updateActive(_active.copyWith(body: pretty));
    } catch (_) {}
  }

  Future<void> sendRequest() async {
    if (_active.url.isEmpty) return;

    _updateActive(
        _active.copyWith(isLoading: true, clearError: true, clearResponse: true));

    try {
      final apiClient = ApiClient();
      final response = await apiClient.sendRequest(
        url: _active.url,
        method: _active.method,
        headers:
            _active.effectiveHeaders.isNotEmpty ? _active.effectiveHeaders : null,
        queryParams:
            _active.effectiveParams.isNotEmpty ? _active.effectiveParams : null,
        body: _active.body.isNotEmpty ? _active.body : null,
      );

      _updateActive(_active.copyWith(isLoading: false, response: response));

      // Save to history
      try {
        await HistoryService.saveHistoryItem(HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: _active.url,
          method: _active.method,
          statusCode: response.statusCode,
          durationMs: response.durationMs,
          timestamp: DateTime.now(),
          requestHeaders: _active.headersMap.isNotEmpty
              ? jsonEncode(_active.headersMap)
              : null,
          requestBody: _active.body.isNotEmpty ? _active.body : null,
          responseBody: response.body,
          queryParams: _active.paramsMap.isNotEmpty
              ? jsonEncode(_active.paramsMap)
              : null,
        ));
      } catch (_) {}
    } catch (e) {
      _updateActive(_active.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void loadFromHistory(HistoryItem item) {
    List<KeyValuePair> headerPairs = [];
    if (item.requestHeaders != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(item.requestHeaders!);
        headerPairs = parsed.entries
            .map((e) => KeyValuePair(key: e.key, value: e.value.toString()))
            .toList();
      } catch (_) {}
    }

    List<KeyValuePair> paramPairs = [];
    if (item.queryParams != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(item.queryParams!);
        paramPairs = parsed.entries
            .map((e) => KeyValuePair(key: e.key, value: e.value.toString()))
            .toList();
      } catch (_) {}
    }

    // Load into a new tab
    final newTab = RequestTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      state: RequestState(
        url: item.url,
        method: item.method,
        headers: headerPairs.isNotEmpty ? headerPairs : defaultHeaders,
        params: paramPairs,
        body: item.requestBody ?? '',
      ),
    );
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(tabs: newTabs, activeIndex: newTabs.length - 1);
  }

  /// Load a saved request from a collection into a new tab
  void loadSavedRequest({
    required String url,
    required String method,
    required List<KeyValuePair> headers,
    required List<KeyValuePair> params,
    required String body,
    AuthConfig auth = const AuthConfig(),
  }) {
    final newTab = RequestTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      state: RequestState(
        url: url,
        method: method,
        headers: headers.isNotEmpty ? headers : defaultHeaders,
        params: params,
        body: body,
        auth: auth,
      ),
    );
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(tabs: newTabs, activeIndex: newTabs.length - 1);
  }
}

// ──────────────── Provider ────────────────
final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
});
