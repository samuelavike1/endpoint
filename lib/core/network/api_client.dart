import 'dart:convert';
import 'package:dio/dio.dart';

class ApiResponse {
  final int statusCode;
  final int durationMs;
  final String body;
  final int sizeBytes;
  final Map<String, dynamic> responseHeaders;
  final String statusMessage;

  ApiResponse({
    required this.statusCode,
    required this.durationMs,
    required this.body,
    required this.sizeBytes,
    required this.responseHeaders,
    this.statusMessage = '',
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => true, // Accept all status codes
      ),
    );
  }

  Future<ApiResponse> sendRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? body,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Clean up the URL
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Parse body as JSON if possible
      dynamic requestBody;
      if (body != null && body.trim().isNotEmpty) {
        try {
          requestBody = jsonDecode(body);
        } catch (_) {
          requestBody = body;
        }
      }

      // Filter out Accept-Encoding from custom headers — let Dio handle compression
      // natively, otherwise we get raw gzip bytes that aren't decompressed.
      final Map<String, String>? filteredHeaders;
      if (headers != null && headers.isNotEmpty) {
        filteredHeaders = Map.fromEntries(
          headers.entries.where(
            (e) => e.key.toLowerCase() != 'accept-encoding',
          ),
        );
      } else {
        filteredHeaders = null;
      }

      final response = await _dio.request(
        cleanUrl,
        data: requestBody,
        queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
        options: Options(
          method: method,
          headers: filteredHeaders?.isNotEmpty == true ? filteredHeaders : null,
          // Use default responseType so Dio handles encoding/decoding properly
        ),
      );

      stopwatch.stop();

      // Convert response data to a readable string
      String responseBody;
      if (response.data == null) {
        responseBody = '';
      } else if (response.data is Map || response.data is List) {
        responseBody = const JsonEncoder.withIndent('  ').convert(response.data);
      } else {
        responseBody = response.data.toString();
        // Try to parse as JSON and pretty-print
        try {
          final parsed = jsonDecode(responseBody);
          responseBody = const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (_) {
          // keep as-is
        }
      }

      // Convert headers
      final Map<String, dynamic> respHeaders = {};
      response.headers.forEach((name, values) {
        respHeaders[name] = values.join(', ');
      });

      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        durationMs: stopwatch.elapsedMilliseconds,
        body: responseBody,
        sizeBytes: responseBody.length,
        responseHeaders: respHeaders,
        statusMessage: response.statusMessage ?? '',
      );
    } on DioException catch (e) {
      stopwatch.stop();

      if (e.response != null) {
        String responseBody;
        if (e.response?.data == null) {
          responseBody = '';
        } else if (e.response?.data is Map || e.response?.data is List) {
          responseBody =
              const JsonEncoder.withIndent('  ').convert(e.response?.data);
        } else {
          responseBody = e.response?.data?.toString() ?? '';
          try {
            final parsed = jsonDecode(responseBody);
            responseBody = const JsonEncoder.withIndent('  ').convert(parsed);
          } catch (_) {}
        }

        final Map<String, dynamic> respHeaders = {};
        e.response?.headers.forEach((name, values) {
          respHeaders[name] = values.join(', ');
        });

        return ApiResponse(
          statusCode: e.response?.statusCode ?? 0,
          durationMs: stopwatch.elapsedMilliseconds,
          body: responseBody,
          sizeBytes: responseBody.length,
          responseHeaders: respHeaders,
          statusMessage: e.response?.statusMessage ?? '',
        );
      }

      // Network error
      String errorMsg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMsg = 'Connection timed out';
          break;
        case DioExceptionType.sendTimeout:
          errorMsg = 'Request send timed out';
          break;
        case DioExceptionType.receiveTimeout:
          errorMsg = 'Response receive timed out';
          break;
        case DioExceptionType.connectionError:
          errorMsg = 'Could not connect to server';
          break;
        default:
          errorMsg = e.message ?? 'Unknown error occurred';
      }

      return ApiResponse(
        statusCode: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        body: errorMsg,
        sizeBytes: 0,
        responseHeaders: {},
        statusMessage: 'Error',
      );
    } catch (e) {
      stopwatch.stop();
      return ApiResponse(
        statusCode: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        body: e.toString(),
        sizeBytes: 0,
        responseHeaders: {},
        statusMessage: 'Error',
      );
    }
  }
}
