import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
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

  /// How long to wait before each retry of a connection failure.
  /// Two entries means two retries; see coldStartRetry().
  static const List<Duration> retryDelays = [
    Duration(seconds: 3),
    Duration(seconds: 12),
  ];
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
  ///  - two attempts, 3s then 12s. Enough for a container to wake or a deploy
  ///    to finish; not so many that a dead network hangs for a minute.
  static Interceptor coldStartRetry() {
    return InterceptorsWrapper(
      onError: (DioException e, handler) async {
        final isConnectionFailure = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        final optedOut = e.requestOptions.extra['noRetry'] == true;
        if (!isConnectionFailure || optedOut) {
          return handler.next(e);
        }

        /*
         * The waits LOOP here rather than relying on this interceptor firing
         * again, because it cannot: the retry goes through a bare Dio with no
         * interceptors attached, so a second attempt driven by re-entry would
         * never happen. That is why a single 3-second retry was all this ever
         * did, whatever the delay list said.
         *
         * And one 3-second retry does not cover the case it was written for. A
         * Render container that has gone to sleep takes 30-50 seconds to wake,
         * and a deploy restarts it for about as long — a tester who hits either
         * window fails on both attempts and is told the connection errored.
         * Three seconds then twelve covers a restart, without leaving somebody
         * staring at a spinner for a minute when the network is simply down.
         */
        final retryClient = Dio(BaseOptions(
          baseUrl: e.requestOptions.baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          sendTimeout: sendTimeout,
        ));
        for (final delay in retryDelays) {
          await Future<void>.delayed(delay);
          try {
            final response = await retryClient.fetch(e.requestOptions);
            return handler.resolve(response);
          } catch (_) {
            // Try the next wait, if there is one.
          }
        }
        // Every attempt failed — surface the ORIGINAL error, which is the one
        // that describes what actually went wrong.
        return handler.next(e);
      },
    );
  }

  /// Apply the standard setup to an existing Dio.
  static void apply(Dio dio, String baseUrl) {
    dio.options = baseOptions(baseUrl);
    dio.interceptors.add(logger());
    dio.interceptors.add(coldStartRetry());
    sessionGuard(dio);
  }

  /// True while a sign-out for an expired session is in progress, so twenty
  /// parallel 401s from one dashboard load produce one redirect.
  static bool _signingOut = false;

  /// What the guard did last, for tests and for a screen that wants to know.
  static int expiredSessionsHandled = 0;

  /// A test seam: the storage wipe and the navigation, replaceable.
  @visibleForTesting
  static Future<void> Function()? onSessionExpired;

  @visibleForTesting
  static void resetSessionGuard() {
    _signingOut = false;
    expiredSessionsHandled = 0;
  }

  /// Signs the user out when their session has expired.
  ///
  /// Every service wrapped a Dio failure into a plain Exception(message) and
  /// every controller caught that into `error.value` — so a 401 on a dead
  /// token was indistinguishable from any other failure, and every screen
  /// drew its empty state: "Hi, Sam!", Collected from guests ₹0, 0 bookings,
  /// 0 properties, "No upcoming bookings", on an account with five bookings
  /// and two listings (2026-09-11, the morning after the host signed in).
  /// Nothing said "you are signed out"; the app looked like it had lost the
  /// data. The website's axios interceptor has always done this.
  ///
  /// Only a request that CARRIED a token counts: a 401 with no bearer is a
  /// signed-out guest hitting a signed-in endpoint, which the screens handle
  /// themselves — and a wrong password on the login endpoint sends none.
  static void sessionGuard(Dio dio) {
    dio.interceptors.add(sessionGuardInterceptor());
  }

  /// The guard itself, for a Dio built with a cascade.
  static Interceptor sessionGuardInterceptor() => InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.response?.statusCode == 401 &&
              _carriedAToken(e.requestOptions)) {
            await _expireSession();
          }
          handler.next(e);
        },
      );

  static bool _carriedAToken(RequestOptions o) {
    final auth = (o.headers['Authorization'] ?? '').toString().trim();
    if (!auth.startsWith('Bearer ')) return false;
    final token = auth.substring(7).trim();
    return token.isNotEmpty && token != 'null';
  }

  static Future<void> _expireSession() async {
    if (_signingOut) return;
    _signingOut = true;
    expiredSessionsHandled += 1;
    try {
      final override = onSessionExpired;
      if (override != null) {
        await override();
        return;
      }
      try {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'user_token');
        await storage.delete(key: 'user_data');
      } catch (_) {}
      if (Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
        Get.snackbar(
          'Signed out',
          'Your session has expired. Please sign in again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      // Hold the latch a moment so the burst of parallel 401s that follows a
      // dashboard load cannot each restart the sign-out.
      Future<void>.delayed(const Duration(seconds: 3), () => _signingOut = false);
    }
  }
}
