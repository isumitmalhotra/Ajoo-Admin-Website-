import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Shared Dio setup: sensible timeouts, one retry for a sleeping backend, and
/// request logging that stays out of release builds.
///
/// WHY THIS EXISTS
///
/// Each service built its own Dio, and most of them set no timeouts at all —
/// Dio's default is none, so a request to an unreachable or waking host hangs
/// on the OS timeout, leaving the user on a spinner with no way to tell whether
/// anything is happening.
///
/// The backend is on Render's **free tier, which sleeps after ~15 minutes of
/// inactivity** (see KEEP_ALIVE_SETUP.md). The first request after a sleep has
/// to wake the container: it can take 30–50 seconds, and while the instance is
/// coming up a connection attempt can fail outright rather than merely being
/// slow. That is the most likely reason a login shows "No route to host" while
/// the server is perfectly healthy a minute later.
///
/// So: connect timeouts short enough to fail fast, a receive timeout long
/// enough to survive a cold start, and ONE automatic retry on a connection
/// failure — which is exactly the shape of a wake-up.
class DioConfig {
  DioConfig._();

  /// Long enough for a Render container to wake, short enough that a genuinely
  /// dead network gives up rather than hanging forever.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);

  static BaseOptions baseOptions(String baseUrl) => BaseOptions(
        baseUrl: baseUrl,
        contentType: 'application/json',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
      );

  /// Request/response logging. `enabled: kDebugMode` is the important part:
  /// these interceptors print request BODIES and response BODIES, which on the
  /// auth calls means passwords going out and JWTs coming back, written to
  /// logcat on every user's device. Debug builds only.
  static PrettyDioLogger logger() => PrettyDioLogger(
        requestHeader: kDebugMode,
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        enabled: kDebugMode,
      );

  /// Retries once when the connection itself failed — the signature of a
  /// backend that is waking up. Deliberately narrow:
  ///
  ///  - only connection/timeout errors, never a real HTTP response. A 4xx is an
  ///    answer, and repeating it just doubles the load.
  ///  - only idempotent-by-intent calls are safe to repeat blindly, so anything
  ///    that creates money movement opts out via `extra['noRetry'] = true`.
  ///  - one attempt, after a short pause. More would just extend the spinner.
  static Interceptor coldStartRetry() {
    return InterceptorsWrapper(
      onError: (DioException e, handler) async {
        final isConnectionFailure = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        final alreadyRetried = e.requestOptions.extra['__retried'] == true;
        final optedOut = e.requestOptions.extra['noRetry'] == true;

        if (!isConnectionFailure || alreadyRetried || optedOut) {
          return handler.next(e);
        }

        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          final options = e.requestOptions;
          options.extra = {...options.extra, '__retried': true};
          final dio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            sendTimeout: sendTimeout,
          ));
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } catch (_) {
          // The retry failed too — surface the ORIGINAL error, which is the one
          // that describes what actually went wrong.
          return handler.next(e);
        }
      },
    );
  }

  /// Apply the standard setup to an existing Dio.
  static void apply(Dio dio, String baseUrl) {
    dio.options = baseOptions(baseUrl);
    dio.interceptors.add(logger());
    dio.interceptors.add(coldStartRetry());
  }
}
