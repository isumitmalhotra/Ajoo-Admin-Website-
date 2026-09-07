/// Listing photographs must be landscape.
///
/// The guest gallery — on the website and here — lays out wide frames. A
/// portrait photograph in one is letterboxed: the picture shrinks to fit the
/// height and the rest of the frame fills with blank. On the live site that
/// produced listings whose lead image was a thin strip of photo between two
/// broad empty panels.
///
/// It cannot be fixed where it is shown. Cropping a portrait to a wide frame
/// throws most of the room away and stretching it is worse, so the only place
/// to solve it is the picker.
///
/// The server applies the same rule to what Cloudinary reports, so nothing
/// reaches a listing unchecked. This exists so a host is told while they are
/// still looking at the photograph, instead of after uploading several of them
/// over mobile data and having them refused.
library;

import 'dart:io';
import 'dart:ui' as ui;

/// How much wider than tall a photo has to be.
///
/// Kept identical to MIN_LANDSCAPE_RATIO in the backend
/// (controllers/listingMedia.controller.js) and the web client
/// (src/redesign/lib/imageRules.ts). 1.2 rather than 1.0 because a square
/// letterboxes almost as badly as a portrait. It sits below every ratio a
/// camera produces in landscape — 4:3 is 1.33, 3:2 is 1.5, 16:9 is 1.78 — and
/// well above portrait (0.75), so it refuses what it should without arguing
/// with real photographs.
const double kMinLandscapeRatio = 1.2;

class PhotoVerdict {
  const PhotoVerdict(this.file, {required this.ok, this.width, this.height});
  final File file;
  final bool ok;
  final int? width;
  final int? height;

  String get shape {
    if (width == null || height == null) return 'is not landscape';
    if (width == height) return 'is square (${width}x$height)';
    if (width! < height!) return 'is portrait (${width}x$height)';
    return 'is nearly square (${width}x$height)';
  }
}

/// Decoded dimensions, with any rotation flag already applied.
///
/// A phone photograph is very often STORED landscape with an EXIF flag that
/// makes it DISPLAY portrait. Flutter's decoder applies that flag, so these are
/// the dimensions a guest will actually see — reading the raw header instead
/// would wave those files through and put the very picture we are refusing on
/// the page.
Future<PhotoVerdict> checkLandscape(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final decoded = await ui.instantiateImageCodec(bytes);
    final frame = await decoded.getNextFrame();
    final w = frame.image.width;
    final h = frame.image.height;
    frame.image.dispose();
    decoded.dispose();
    if (w == 0 || h == 0) return PhotoVerdict(file, ok: true);
    return PhotoVerdict(file, ok: w / h >= kMinLandscapeRatio, width: w, height: h);
  } catch (_) {
    // A file we cannot measure is ALLOWED through: the server checks the same
    // rule, so nothing gets onto a listing unchecked, and refusing here on a
    // decode failure would only stop a host uploading a perfectly good photo.
    return PhotoVerdict(file, ok: true);
  }
}

/// One message naming what was refused and why.
String landscapeMessage(List<PhotoVerdict> rejected) {
  final head = rejected.length == 1
      ? 'That photo ${rejected.first.shape}.'
      : '${rejected.length} photos are not landscape.';
  return '$head Listing photos must be landscape — at least '
      '${kMinLandscapeRatio}x wider than tall — or they show with blank bars '
      'either side. Rotate or re-crop and try again.';
}
