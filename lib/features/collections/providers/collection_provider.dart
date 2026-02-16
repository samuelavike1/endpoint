import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/collection_service.dart';
import '../../home/providers/request_provider.dart';

// ──────────────── Collection State ────────────────
class CollectionState {
  final List<Collection> collections;
  final bool isLoading;

  const CollectionState({this.collections = const [], this.isLoading = false});

  CollectionState copyWith({List<Collection>? collections, bool? isLoading}) {
    return CollectionState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ──────────────── Collection Notifier ────────────────
class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier() : super(const CollectionState()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    state = state.copyWith(isLoading: true);
    final collections = await CollectionService.getCollections();
    state = state.copyWith(collections: collections, isLoading: false);
  }

  // ─── Collection CRUD ───

  Future<void> createCollection({
    required String name,
    int colorIndex = 0,
    String description = '',
    String baseUrl = '',
  }) async {
    final collection = Collection(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      baseUrl: baseUrl,
      colorIndex: colorIndex,
    );
    await CollectionService.addCollection(collection);
    await loadCollections();
  }

  Future<void> updateCollectionConfig({
    required String collectionId,
    String? name,
    String? description,
    String? baseUrl,
    int? colorIndex,
    String? sharedHeadersJson,
    String? sharedAuthJson,
    Map<String, String>? variables,
    bool clearSharedHeaders = false,
    bool clearSharedAuth = false,
  }) async {
    final collections = [...state.collections];
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      collections[index] = collections[index].copyWith(
        name: name,
        description: description,
        baseUrl: baseUrl,
        colorIndex: colorIndex,
        sharedHeadersJson: sharedHeadersJson,
        sharedAuthJson: sharedAuthJson,
        variables: variables,
        clearSharedHeaders: clearSharedHeaders,
        clearSharedAuth: clearSharedAuth,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  Future<void> deleteCollection(String id) async {
    await CollectionService.deleteCollection(id);
    await loadCollections();
  }

  Future<void> duplicateCollection(String collectionId) async {
    final original = state.collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw Exception('Collection not found'),
    );
    final copy = Collection(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      description: original.description,
      baseUrl: original.baseUrl,
      colorIndex: original.colorIndex,
      sharedHeadersJson: original.sharedHeadersJson,
      sharedAuthJson: original.sharedAuthJson,
      variables: Map<String, String>.from(original.variables),
      requests: original.requests
          .map(
            (r) => SavedRequest(
              id: 'req_${DateTime.now().millisecondsSinceEpoch}_${r.id}',
              name: r.name,
              description: r.description,
              url: r.url,
              method: r.method,
              headersJson: r.headersJson,
              paramsJson: r.paramsJson,
              body: r.body,
              authJson: r.authJson,
            ),
          )
          .toList(),
    );
    await CollectionService.addCollection(copy);
    await loadCollections();
  }

  // ─── Variable operations ───

  Future<void> setVariable({
    required String collectionId,
    required String key,
    required String value,
  }) async {
    final collections = [...state.collections];
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final vars = Map<String, String>.from(collections[index].variables);
      vars[key] = value;
      collections[index] = collections[index].copyWith(
        variables: vars,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  Future<void> removeVariable({
    required String collectionId,
    required String key,
  }) async {
    final collections = [...state.collections];
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final vars = Map<String, String>.from(collections[index].variables);
      vars.remove(key);
      collections[index] = collections[index].copyWith(
        variables: vars,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  Future<void> updateVariables({
    required String collectionId,
    required Map<String, String> variables,
  }) async {
    final collections = [...state.collections];
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      collections[index] = collections[index].copyWith(
        variables: variables,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  // ─── Request operations ───

  Future<void> addRequestToCollection({
    required String collectionId,
    required SavedRequest request,
  }) async {
    final collections = [...state.collections];
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final updatedRequests = [...collections[index].requests, request];
      collections[index] = collections[index].copyWith(
        requests: updatedRequests,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  Future<void> saveCurrentRequest({
    required String collectionId,
    required RequestState requestState,
    String? name,
    String? description,
  }) async {
    final request = SavedRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? _deriveRequestName(requestState),
      description: description ?? '',
      url: requestState.url,
      method: requestState.method,
      headersJson: requestState.headersMap.isNotEmpty
          ? jsonEncode(requestState.headersMap)
          : null,
      paramsJson: requestState.paramsMap.isNotEmpty
          ? jsonEncode(requestState.paramsMap)
          : null,
      body: requestState.body.isNotEmpty ? requestState.body : null,
      authJson: requestState.auth.type != AuthType.none
          ? jsonEncode(requestState.auth.toJson())
          : null,
    );
    await addRequestToCollection(collectionId: collectionId, request: request);
  }

  Future<void> addBlankRequest(String collectionId) async {
    final request = SavedRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      name: 'New Request',
      url: '',
      method: 'GET',
    );
    await addRequestToCollection(collectionId: collectionId, request: request);
  }

  Future<void> updateRequest({
    required String collectionId,
    required SavedRequest updatedRequest,
  }) async {
    final collections = [...state.collections];
    final colIdx = collections.indexWhere((c) => c.id == collectionId);
    if (colIdx != -1) {
      final requests = [...collections[colIdx].requests];
      final reqIdx = requests.indexWhere((r) => r.id == updatedRequest.id);
      if (reqIdx != -1) {
        requests[reqIdx] = updatedRequest;
        collections[colIdx] = collections[colIdx].copyWith(
          requests: requests,
          updatedAt: DateTime.now(),
        );
        await CollectionService.saveCollections(collections);
        state = state.copyWith(collections: collections);
      }
    }
  }

  Future<void> removeRequest(String collectionId, String requestId) async {
    final collections = [...state.collections];
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final updatedRequests = collections[index].requests
          .where((r) => r.id != requestId)
          .toList();
      collections[index] = collections[index].copyWith(
        requests: updatedRequests,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  Future<void> duplicateRequest(String collectionId, String requestId) async {
    final collections = [...state.collections];
    final colIdx = collections.indexWhere((c) => c.id == collectionId);
    if (colIdx != -1) {
      final requests = collections[colIdx].requests;
      final original = requests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => throw Exception('Request not found'),
      );
      final copy = original.copyWith(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        name: '${original.name} (Copy)',
      );
      final updatedRequests = [...requests, copy];
      collections[colIdx] = collections[colIdx].copyWith(
        requests: updatedRequests,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  Future<void> reorderRequests(
    String collectionId,
    int oldIndex,
    int newIndex,
  ) async {
    final collections = [...state.collections];
    final colIdx = collections.indexWhere((c) => c.id == collectionId);
    if (colIdx != -1) {
      final requests = [...collections[colIdx].requests];
      if (newIndex > oldIndex) newIndex -= 1;
      final item = requests.removeAt(oldIndex);
      requests.insert(newIndex, item);
      collections[colIdx] = collections[colIdx].copyWith(
        requests: requests,
        updatedAt: DateTime.now(),
      );
      await CollectionService.saveCollections(collections);
      state = state.copyWith(collections: collections);
    }
  }

  // ── Helpers ──

  Collection? getCollection(String id) {
    try {
      return state.collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String _deriveRequestName(RequestState requestState) {
    final url = requestState.url;
    if (url.isEmpty) return '${requestState.method} Request';
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        return last.isEmpty ? uri.host : last;
      }
      return uri.host;
    } catch (_) {
      return url.length > 30 ? '${url.substring(0, 27)}...' : url;
    }
  }
}

// ──────────────── Provider ────────────────
final collectionProvider =
    StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
      return CollectionNotifier();
    });
