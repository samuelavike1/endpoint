import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/data/history_service.dart';

// ──────────────── Request State ────────────────
class RequestState {
  final String url;
  final String method;
  final List<KeyValuePair> headers;
  final List<KeyValuePair> params;
  final String body;
  final ApiResponse? response;
  final bool isLoading;
  final String? error;
  final int activeTabIndex; // 0=Params, 1=Headers, 2=Body, 3=Auth

  const RequestState({
    this.url = '',
    this.method = 'GET',
    this.headers = const [],
    this.params = const [],
    this.body = '',
    this.response,
    this.isLoading = false,
    this.error,
    this.activeTabIndex = 0,
  });

  RequestState copyWith({
    String? url,
    String? method,
    List<KeyValuePair>? headers,
    List<KeyValuePair>? params,
    String? body,
    ApiResponse? response,
    bool? isLoading,
    String? error,
    int? activeTabIndex,
    bool clearResponse = false,
    bool clearError = false,
  }) {
    return RequestState(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      body: body ?? this.body,
      response: clearResponse ? null : (response ?? this.response),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }

  Map<String, String> get headersMap {
    final map = <String, String>{};
    for (final pair in headers) {
      if (pair.enabled && pair.key.isNotEmpty) {
        map[pair.key] = pair.value;
      }
    }
    return map;
  }

  Map<String, String> get paramsMap {
    final map = <String, String>{};
    for (final pair in params) {
      if (pair.enabled && pair.key.isNotEmpty) {
        map[pair.key] = pair.value;
      }
    }
    return map;
  }
}

class KeyValuePair {
  final String key;
  final String value;
  final bool enabled;

  const KeyValuePair({
    this.key = '',
    this.value = '',
    this.enabled = true,
  });

  KeyValuePair copyWith({String? key, String? value, bool? enabled}) {
    return KeyValuePair(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }
}

// ──────────────── Default Headers ────────────────
const List<KeyValuePair> defaultHeaders = [
  KeyValuePair(key: 'Content-Type', value: 'application/json', enabled: true),
  KeyValuePair(key: 'Accept', value: 'application/json', enabled: true),
  KeyValuePair(key: 'User-Agent', value: 'Endpoint/1.0', enabled: true),
  KeyValuePair(key: 'Connection', value: 'keep-alive', enabled: true),
  KeyValuePair(key: 'Cache-Control', value: 'no-cache', enabled: false),
];

// ──────────────── Request Notifier ────────────────
class RequestNotifier extends StateNotifier<RequestState> {
  RequestNotifier() : super(const RequestState(headers: defaultHeaders));

  void updateUrl(String url) => state = state.copyWith(url: url);

  void updateMethod(String method) => state = state.copyWith(method: method);

  void updateBody(String body) => state = state.copyWith(body: body);

  void setActiveTab(int index) => state = state.copyWith(activeTabIndex: index);

  void updateHeaders(List<KeyValuePair> headers) =>
      state = state.copyWith(headers: headers);

  void updateParams(List<KeyValuePair> params) =>
      state = state.copyWith(params: params);

  void clearResponse() =>
      state = state.copyWith(clearResponse: true, clearError: true);

  void prettifyBody() {
    if (state.body.trim().isEmpty) return;
    try {
      final parsed = jsonDecode(state.body);
      final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
      state = state.copyWith(body: pretty);
    } catch (_) {
      // Not valid JSON, do nothing
    }
  }

  Future<void> sendRequest() async {
    if (state.url.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true, clearResponse: true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.sendRequest(
        url: state.url,
        method: state.method,
        headers: state.headersMap.isNotEmpty ? state.headersMap : null,
        queryParams: state.paramsMap.isNotEmpty ? state.paramsMap : null,
        body: state.body.isNotEmpty ? state.body : null,
      );

      state = state.copyWith(
        isLoading: false,
        response: response,
      );

      // Save to history
      try {
        await HistoryService.saveHistoryItem(HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: state.url,
          method: state.method,
          statusCode: response.statusCode,
          durationMs: response.durationMs,
          timestamp: DateTime.now(),
          requestHeaders: state.headersMap.isNotEmpty
              ? jsonEncode(state.headersMap)
              : null,
          requestBody: state.body.isNotEmpty ? state.body : null,
          responseBody: response.body,
          queryParams: state.paramsMap.isNotEmpty
              ? jsonEncode(state.paramsMap)
              : null,
        ));
      } catch (_) {
        // Silently fail on history save
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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

    state = RequestState(
      url: item.url,
      method: item.method,
      headers: headerPairs,
      params: paramPairs,
      body: item.requestBody ?? '',
    );
  }
}

// ──────────────── History State ────────────────
class HistoryState {
  final List<HistoryItem> items;
  final bool isLoading;

  const HistoryState({this.items = const [], this.isLoading = false});

  HistoryState copyWith({List<HistoryItem>? items, bool? isLoading}) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    final items = await HistoryService.getHistory();
    state = state.copyWith(items: items, isLoading: false);
  }

  Future<void> deleteItem(String id) async {
    await HistoryService.deleteHistoryItem(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await HistoryService.clearHistory();
    state = state.copyWith(items: []);
  }
}

// ──────────────── Providers ────────────────
final requestProvider =
    StateNotifierProvider<RequestNotifier, RequestState>((ref) {
  return RequestNotifier();
});

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});

// Navigation state
final selectedTabProvider = StateProvider<int>((ref) => 0);
