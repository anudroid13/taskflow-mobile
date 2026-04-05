import 'package:dio/dio.dart';

class ErrorHandler {
  ErrorHandler._();

  static String getMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    return 'An unexpected error occurred.';
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  static String _handleStatusCode(Response? response) {
    if (response == null) return 'No response from server.';

    final data = response.data;
    final detail = data is Map ? data['detail'] : null;

    switch (response.statusCode) {
      case 400:
        return detail?.toString() ?? 'Bad request.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return detail?.toString() ?? 'Resource not found.';
      case 409:
        return detail?.toString() ?? 'Conflict: resource already exists.';
      case 413:
        return 'File is too large. Maximum size is 10 MB.';
      case 422:
        if (detail is List && detail.isNotEmpty) {
          final first = detail[0];
          if (first is Map && first.containsKey('msg')) {
            return first['msg'].toString();
          }
        }
        return detail?.toString() ?? 'Validation error.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return detail?.toString() ?? 'Something went wrong.';
    }
  }
}
