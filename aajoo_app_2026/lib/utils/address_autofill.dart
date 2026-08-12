import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Filling an address form without typing it (A-67).
///
/// Two ways in: where the phone is, or a PIN code. Both end at the same
/// platform geocoder the map and the host listing form already use — no new
/// service, no key, nothing to bill.
///
/// Everything here is time-boxed and swallows its failures into null.
/// `getCurrentPosition` can hang indoors and fails outright with GPS off; when
/// the map screen called it unguarded, the loader stayed up forever with no
/// way out. A null here means "we could not help, type it yourself", which is
/// a working form.
class AddressParts {
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  const AddressParts({
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
  });

  /// True when the lookup produced nothing worth writing into a form. A
  /// placemark can come back technically successful and entirely blank.
  bool get isEmpty =>
      address.trim().isEmpty &&
      city.trim().isEmpty &&
      postalCode.trim().isEmpty;

  static AddressParts _from(Placemark p) {
    final street = [p.street, p.subLocality]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');
    return AddressParts(
      address: street,
      city: p.locality ?? '',
      state: p.administrativeArea ?? '',
      country: p.country ?? '',
      postalCode: p.postalCode ?? '',
    );
  }
}

/// Why a lookup produced nothing, so the caller can say something useful
/// rather than a generic failure.
enum AddressLookupError { permissionDenied, permissionForever, notFound, failed }

class AddressLookupResult {
  final AddressParts? parts;
  final AddressLookupError? error;
  const AddressLookupResult.ok(this.parts) : error = null;
  const AddressLookupResult.fail(this.error) : parts = null;
  bool get ok => parts != null;
}

/// Where the phone is, turned into address fields.
Future<AddressLookupResult> addressFromCurrentLocation() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const AddressLookupResult.fail(
          AddressLookupError.permissionForever);
    }
    if (permission == LocationPermission.denied) {
      return const AddressLookupResult.fail(AddressLookupError.permissionDenied);
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      // A fix we already had beats no answer at all.
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      return const AddressLookupResult.fail(AddressLookupError.failed);
    }

    final marks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (marks.isEmpty) {
      return const AddressLookupResult.fail(AddressLookupError.notFound);
    }
    final parts = AddressParts._from(marks.first);
    if (parts.isEmpty) {
      return const AddressLookupResult.fail(AddressLookupError.notFound);
    }
    return AddressLookupResult.ok(parts);
  } catch (_) {
    return const AddressLookupResult.fail(AddressLookupError.failed);
  }
}

/// A PIN code, turned into city and state.
///
/// Deliberately does NOT return a street: a PIN covers a whole area, and
/// writing a guessed street into the user's address is worse than leaving the
/// field for them. It fills what a PIN genuinely determines.
Future<AddressLookupResult> addressFromPostalCode(String pin) async {
  final code = pin.trim();
  if (code.length < 4) {
    return const AddressLookupResult.fail(AddressLookupError.notFound);
  }
  try {
    // Scoped to India — a bare six-digit string matches postcodes in several
    // countries, and the geocoder will happily return the wrong one.
    final locations = await locationFromAddress('$code, India');
    if (locations.isEmpty) {
      return const AddressLookupResult.fail(AddressLookupError.notFound);
    }
    final marks = await placemarkFromCoordinates(
        locations.first.latitude, locations.first.longitude);
    if (marks.isEmpty) {
      return const AddressLookupResult.fail(AddressLookupError.notFound);
    }
    final p = marks.first;
    final parts = AddressParts(
      city: p.locality ?? '',
      state: p.administrativeArea ?? '',
      country: p.country ?? '',
      // Keep what the user typed; the geocoder sometimes answers with the
      // PIN of the area centroid rather than the one asked for.
      postalCode: code,
    );
    if (parts.city.trim().isEmpty) {
      return const AddressLookupResult.fail(AddressLookupError.notFound);
    }
    return AddressLookupResult.ok(parts);
  } catch (_) {
    return const AddressLookupResult.fail(AddressLookupError.failed);
  }
}

/// One place to turn a failure into something a person can act on.
String addressLookupMessage(AddressLookupError? e) {
  switch (e) {
    case AddressLookupError.permissionDenied:
      return 'Location permission is needed to fill this in.';
    case AddressLookupError.permissionForever:
      return 'Location is blocked for Aajoo. Turn it on in your phone settings.';
    case AddressLookupError.notFound:
      return "Couldn't find that. Please type it in.";
    case AddressLookupError.failed:
    default:
      return "Couldn't get your location. Please type it in.";
  }
}
