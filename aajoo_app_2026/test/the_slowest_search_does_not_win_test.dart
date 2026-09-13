import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/service/map_service.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';

/// §3.20 — "Nearby comes back empty on a cold launch", and why.
///
/// The report: granting location fills the home screen with "1 home in
/// Gurugram", but a COLD RELAUNCH at the same coordinates shows "No stays here
/// yet" — while `POST /properties/search` with exactly those coordinates and
/// no filters returns 1 from curl in under two seconds. Every filter the app
/// adds is null on a cold start, so the two requests are the same request. It
/// stayed open because a release build logs nothing and the emulator's own
/// location stack is a poor witness.
///
/// It is not a request problem. It is an ORDERING one, and it needs two
/// searches in flight to show itself:
///
///   getCurrentLocation() returns the LAST KNOWN position at once and fires
///   _refineLocation() in the background. fetchProperties then searches at
///   that last-known point. Two getProperties() calls are now running, and
///   both ended by assigning straight into `properties` — so whichever
///   finished LAST won, however old it was.
///
/// The foreground search answers in ~2s with the right stays. The background
/// refine can land at a different fix, find nothing, walk out to the planetary
/// ring (~92 seconds, measured) and then overwrite a correct screen with its
/// own answer. From the outside: a home that had stays and then did not, with
/// no error anywhere.
///
/// These tests make the slow search slow on purpose, which is the only way to
/// pin an ordering fault — pointing at a real server and hoping is not a test.
class _StubMapService extends MapService {
  _StubMapService(this.plan);

  /// Per call, in order: how long to take, and what to answer with.
  final List<({Duration delay, int count})> plan;
  int calls = 0;

  @override
  Future<PropertiesResponse?> getProperties(
    double lat,
    double long, {
    int category = 0,
    String radius = "",
    int? guests,
    bool petsAllowed = false,
    String? from,
    String? to,
    bool? isLuxury,
    String? q,
    double? minPrice,
    double? maxPrice,
    Duration? receiveTimeout,
  }) async {
    final step = plan[calls < plan.length ? calls : plan.length - 1];
    calls += 1;
    await Future<void>.delayed(step.delay);
    return PropertiesResponse(
      success: true,
      message: 'ok',
      data: Data(
        // Built through fromJson rather than the constructor: it coerces
        // every field defensively (that was §3.13's fix) so a minimal map is
        // a valid stay, and the test does not have to restate eleven required
        // arguments it does not care about.
        property: List<Property>.generate(
          step.count,
          (i) => Property.fromJson(<String, dynamic>{
            'property_id': i + 1,
            'property_name': 'Stay ${i + 1}',
          }),
        ),
      ),
    );
  }
}

void main() {
  test('a slow search cannot overwrite the answer that replaced it', () async {
    // Call 1 is the cold-start foreground search: slow, and RIGHT.
    // Call 2 is the background refine landing later: fast, and empty.
    final c = MapController()
      ..mapService = _StubMapService([
        (delay: const Duration(milliseconds: 120), count: 1),
        (delay: const Duration(milliseconds: 10), count: 0),
      ]);

    final slow = c.getProperties(28.49, 77.40);
    // Started after, finishes first — exactly the shape of the bug, with the
    // roles reversed so the assertion cannot pass by accident of timing.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final fast = c.getProperties(37.42, -122.08);
    await Future.wait([slow, fast]);

    expect(c.properties.length, 0,
        reason: 'the NEWER search said there is nothing at the new fix; the '
            'older one must not put its stays back on screen');
  });

  test('and the newer answer stands even when the older one found stays',
      () async {
    final c = MapController()
      ..mapService = _StubMapService([
        (delay: const Duration(milliseconds: 120), count: 5),
        (delay: const Duration(milliseconds: 10), count: 2),
      ]);

    final slow = c.getProperties(28.49, 77.40);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final fast = c.getProperties(28.50, 77.41);
    await Future.wait([slow, fast]);

    expect(c.properties.length, 2,
        reason: 'whichever search started last is the one the guest asked for');
  });

  test('a superseded search does not clear the loading flag either', () async {
    // It used to set isLoading false on its way out, so a stale search could
    // stop the shimmer over a fetch that was still running.
    final c = MapController()
      ..mapService = _StubMapService([
        (delay: const Duration(milliseconds: 120), count: 1),
        (delay: const Duration(milliseconds: 400), count: 1),
      ]);

    final slow = c.getProperties(28.49, 77.40);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    c.isLoading.value = true;
    final newer = c.getProperties(28.50, 77.41);
    await slow;

    expect(c.isLoading.value, isTrue,
        reason: 'the search still running owns the shimmer');
    await newer;
  });

  test('a single search still answers normally', () async {
    // The guard must not turn an ordinary fetch into a no-op.
    final c = MapController()
      ..mapService = _StubMapService([(delay: Duration.zero, count: 3)]);
    await c.getProperties(28.49, 77.40);
    expect(c.properties.length, 3);
    expect(c.isLoading.value, isFalse);
    expect(c.lastSearchFailed.value, isFalse);
  });

  test('an empty answer still widens — but a background refine stops short',
      () async {
    // The planetary ring is right for a search somebody is waiting on and
    // wrong for one nobody asked for: ~92 seconds, measured, and then a stay
    // on another continent replacing the ones around the guest.
    final foreground = MapController()
      ..mapService = _StubMapService([(delay: Duration.zero, count: 0)]);
    await foreground.getProperties(28.49, 77.40);
    // first call + the three rings
    expect((foreground.mapService as _StubMapService).calls, 4);

    final background = MapController()
      ..mapService = _StubMapService([(delay: Duration.zero, count: 0)]);
    await background.getProperties(28.49, 77.40,
        rings: MapController.backgroundRings);
    // first call + two rings, never the planetary one
    expect((background.mapService as _StubMapService).calls, 3,
        reason: 'a refine nobody is watching must not walk to the planet');
  });
}
