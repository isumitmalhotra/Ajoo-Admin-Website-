import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';

/// An expired session signs the user out — it does not draw an empty account.
///
/// Found 2026-09-11, the morning after the host signed in: "Hi, Sam!",
/// Collected from guests ₹0, 0 bookings, 0 properties, "No upcoming
/// bookings" — on an account with five bookings and two listings. Every
/// service wrapped the 401 into a plain Exception, every controller caught
/// it into `error.value`, and every screen drew its empty state. Nothing said
/// "you are signed out". The website's axios interceptor has always handled
/// this; the app now has one guard on every Dio it builds.
void main() {
  late HttpServer server;
  late String base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://${server.address.address}:${server.port}';
    server.listen((req) {
      // /me answers 401 to anyone; /login answers 401 as "wrong password".
      req.response.statusCode = 401;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'success': false, 'message': 'token expired'}));
      req.response.close();
    });
    DioConfig.resetSessionGuard();
  });

  tearDown(() async {
    DioConfig.onSessionExpired = null;
    await server.close(force: true);
  });

  Dio guarded() {
    final dio = Dio(BaseOptions(baseUrl: base));
    DioConfig.sessionGuard(dio);
    return dio;
  }

  test('a 401 on a request that carried a token signs the user out', () async {
    var signedOut = 0;
    DioConfig.onSessionExpired = () async => signedOut += 1;

    final dio = guarded();
    dio.options.headers['Authorization'] = 'Bearer eyJ.expired.token';
    await expectLater(dio.get('/host/dashboard'), throwsA(isA<DioException>()),
        reason: 'the failure must still reach the caller — it is the guard '
            'that acts, not the caller');
    // The guard runs before the error is handed on.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(signedOut, 1,
        reason: 'the 401 was swallowed into an error string and the screens '
            'drew an empty account');
  });

  test('a 401 with no token is not a sign-out (a guest, or a wrong password)',
      () async {
    var signedOut = 0;
    DioConfig.onSessionExpired = () async => signedOut += 1;

    final dio = guarded();
    await expectLater(dio.post('/auth/login'), throwsA(isA<DioException>()));
    dio.options.headers['Authorization'] = 'Bearer null';
    await expectLater(dio.get('/user/bookings'), throwsA(isA<DioException>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(signedOut, 0,
        reason: 'a wrong password, or a signed-out guest touching a '
            'signed-in endpoint, must not bounce to the login screen');
  });

  test('a burst of 401s from one screen load signs out once', () async {
    var signedOut = 0;
    DioConfig.onSessionExpired = () async => signedOut += 1;

    final dio = guarded();
    dio.options.headers['Authorization'] = 'Bearer eyJ.expired.token';
    await Future.wait([
      for (var i = 0; i < 6; i++)
        dio.get('/host/x$i').catchError((Object _) => Response(requestOptions: RequestOptions())),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(signedOut, 1, reason: 'six parallel 401s produced $signedOut sign-outs');
  });
}
