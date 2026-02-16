import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────── Saved Request ────────────────
class SavedRequest {
  final String id;
  final String name;
  final String description;
  final String url;
  final String method;
  final String? headersJson;
  final String? paramsJson;
  final String? body;
  final String? authJson;
  final DateTime createdAt;

  SavedRequest({
    required this.id,
    required this.name,
    this.description = '',
    required this.url,
    required this.method,
    this.headersJson,
    this.paramsJson,
    this.body,
    this.authJson,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName {
    if (name.isNotEmpty) return name;
    if (url.isEmpty) return 'Untitled Request';
    return displayUrl;
  }

  String get displayUrl {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (uri.pathSegments.isNotEmpty) {
        return '/${uri.pathSegments.join('/')}';
      }
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  SavedRequest copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    String? method,
    String? headersJson,
    String? paramsJson,
    String? body,
    String? authJson,
    bool clearHeaders = false,
    bool clearParams = false,
    bool clearBody = false,
    bool clearAuth = false,
  }) {
    return SavedRequest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      method: method ?? this.method,
      headersJson: clearHeaders ? null : (headersJson ?? this.headersJson),
      paramsJson: clearParams ? null : (paramsJson ?? this.paramsJson),
      body: clearBody ? null : (body ?? this.body),
      authJson: clearAuth ? null : (authJson ?? this.authJson),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url,
    'method': method,
    'headersJson': headersJson,
    'paramsJson': paramsJson,
    'body': body,
    'authJson': authJson,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedRequest.fromJson(Map<String, dynamic> json) => SavedRequest(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    url: json['url'] as String,
    method: json['method'] as String,
    headersJson: json['headersJson'] as String?,
    paramsJson: json['paramsJson'] as String?,
    body: json['body'] as String?,
    authJson: json['authJson'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

// ──────────────── Collection ────────────────
class Collection {
  final String id;
  final String name;
  final String description;
  final String baseUrl;
  final int colorIndex;
  final String? sharedHeadersJson;
  final String? sharedAuthJson;
  final Map<String, String> variables;
  final List<SavedRequest> requests;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection({
    required this.id,
    required this.name,
    this.description = '',
    this.baseUrl = '',
    this.colorIndex = 0,
    this.sharedHeadersJson,
    this.sharedAuthJson,
    this.variables = const {},
    this.requests = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Substitutes all `{{key}}` placeholders in [input] with variable values.
  String substituteVariables(String input) {
    if (variables.isEmpty || input.isEmpty) return input;
    String result = input;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  Collection copyWith({
    String? name,
    String? description,
    String? baseUrl,
    int? colorIndex,
    String? sharedHeadersJson,
    String? sharedAuthJson,
    Map<String, String>? variables,
    List<SavedRequest>? requests,
    DateTime? updatedAt,
    bool clearSharedHeaders = false,
    bool clearSharedAuth = false,
  }) {
    return Collection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseUrl: baseUrl ?? this.baseUrl,
      colorIndex: colorIndex ?? this.colorIndex,
      sharedHeadersJson: clearSharedHeaders
          ? null
          : (sharedHeadersJson ?? this.sharedHeadersJson),
      sharedAuthJson: clearSharedAuth
          ? null
          : (sharedAuthJson ?? this.sharedAuthJson),
      variables: variables ?? this.variables,
      requests: requests ?? this.requests,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'baseUrl': baseUrl,
    'colorIndex': colorIndex,
    'sharedHeadersJson': sharedHeadersJson,
    'sharedAuthJson': sharedAuthJson,
    'variables': variables,
    'requests': requests.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    baseUrl: json['baseUrl'] as String? ?? '',
    colorIndex: json['colorIndex'] as int? ?? 0,
    sharedHeadersJson: json['sharedHeadersJson'] as String?,
    sharedAuthJson: json['sharedAuthJson'] as String?,
    variables:
        (json['variables'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        {},
    requests:
        (json['requests'] as List<dynamic>?)
            ?.map((r) => SavedRequest.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

// ──────────────── Collection Service ────────────────
class CollectionService {
  static const String _key = 'api_collections';

  static Future<List<Collection>> getCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => Collection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCollections(List<Collection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(collections.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> addCollection(Collection collection) async {
    final collections = await getCollections();
    collections.add(collection);
    await saveCollections(collections);
  }

  static Future<void> updateCollection(Collection collection) async {
    final collections = await getCollections();
    final index = collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      collections[index] = collection;
      await saveCollections(collections);
    }
  }

  static Future<void> deleteCollection(String id) async {
    final collections = await getCollections();
    collections.removeWhere((c) => c.id == id);
    await saveCollections(collections);
  }
}
