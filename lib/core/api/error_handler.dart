import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

String handleDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Check your internet.';
    case DioExceptionType.connectionError:
      return 'No internet connection.';
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (body is Map) {
        if (body['message'] != null) return body['message'] as String;
        if (body['errors'] != null) {
          final errors = body['errors'] as Map;
          return errors.values.first is List
              ? (errors.values.first as List).first.toString()
              : errors.values.first.toString();
        }
      }
      return _httpMessage(code);
    default:
      return 'Something went wrong. Please try again.';
  }
}

String _httpMessage(int? code) {
  switch (code) {
    case 401: return 'Session expired. Please log in again.';
    case 403: return 'You do not have permission to do that.';
    case 404: return 'Resource not found.';
    case 409: return 'Conflict — this action has already been done.';
    case 422: return 'Validation failed. Check your input.';
    case 429: return 'Too many requests. Please wait a moment.';
    case 500: return 'Server error. Please try again later.';
    default:  return 'Request failed (HTTP $code).';
  }
}
