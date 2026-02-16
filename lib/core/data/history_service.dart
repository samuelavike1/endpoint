import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String id;
  final String url;
  final String method;
  final int statusCode;
  final int durationMs;
  final DateTime timestamp;
  final String? requestHeaders;
  final String? requestBody;
  final String? responseBody;
  final String? queryParams;

  HistoryItem({
    required this.id,
    required this.url,
    required this.method,
    required this.statusCode,
    required this.durationMs,
    required this.timestamp,
    this.requestHeaders,
    this.requestBody,
    this.responseBody,
    this.queryParams,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'method': method,
        'statusCode': statusCode,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'requestHeaders': requestHeaders,
        'requestBody': requestBody,
        'responseBody': responseBody,
        'queryParams': queryParams,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String,
        url: json['url'] as String,
        method: json['method'] as String,
        statusCode: json['statusCode'] as int,
        durationMs: json['durationMs'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        requestHeaders: json['requestHeaders'] as String?,
        requestBody: json['requestBody'] as String?,
        responseBody: json['responseBody'] as String?,
        queryParams: json['queryParams'] as String?,
      );

  String get displayUrl {
    try {
      final uri = Uri.parse(url);
      return uri.path.isEmpty || uri.path == '/' ? uri.host : '${uri.host}${uri.path}';
    } catch (_) {
      return url;
    }
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class HistoryService {
  static const String _key = 'request_history';
  static const int _maxItems = 100;

  static Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistoryItem(HistoryItem item) async {
    final history = await getHistory();
    history.insert(0, item);

    // Keep only the most recent items
    final trimmed = history.take(_maxItems).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteHistoryItem(String id) async {
    final history = await getHistory();
    history.removeWhere((item) => item.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
