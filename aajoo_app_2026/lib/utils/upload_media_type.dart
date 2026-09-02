/// What to label a file as when uploading it.
///
/// WHY THIS EXISTS
/// ---------------
/// Dio labels every multipart part `application/octet-stream` unless it is
/// told otherwise — the default is written into `MultipartFile` itself. Not
/// one upload in this app was telling it otherwise, so every photo, every ID
/// document and every profile picture arrived at the server as an anonymous
/// blob of bytes.
///
/// That went unnoticed because most of the server's checks fall back to the
/// file extension. One does not: listing photos are refused outright unless
/// the MIME type starts with `image/`, so hosts uploading a perfectly ordinary
/// JPEG were told their JPEG was not an image
/// (`listingMedia.controller.js` — "Listing photos must be images"). The
/// website was never affected: a browser fills the part type in for you.
///
/// The extension is the only thing we can go on here — reading magic bytes to
/// name a file we are about to hand over for validation anyway would be
/// answering a question the server is already asking.
import 'package:dio/dio.dart';

const Map<String, List<String>> _byExtension = {
  'jpg': ['image', 'jpeg'],
  'jpeg': ['image', 'jpeg'],
  'png': ['image', 'png'],
  'webp': ['image', 'webp'],
  'gif': ['image', 'gif'],
  'bmp': ['image', 'bmp'],
  // iPhones hand these over unconverted often enough to be worth naming.
  'heic': ['image', 'heic'],
  'heif': ['image', 'heif'],
  'pdf': ['application', 'pdf'],
};

/// The media type for [path], or null when the extension is unknown.
///
/// Null rather than a guess: an unrecognised extension is exactly the case
/// where claiming a type would be lying to the validator, and Dio's own
/// default is the honest answer.
DioMediaType? mediaTypeForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return null;
  final ext = path.substring(dot + 1).toLowerCase();
  final parts = _byExtension[ext];
  return parts == null ? null : DioMediaType(parts[0], parts[1]);
}
