/// A Cloudinary image URL the app can always decode.
///
/// Cloudinary delivers what was uploaded unless asked otherwise, and listings
/// can be uploaded as AVIF (property 6 has four, its cover among them). The
/// website shows them — browsers decode AVIF — but Flutter does not, on iOS or
/// Android: Image.network throws and every card falls back to the
/// "image not supported" placeholder.
///
/// `f_auto` asks Cloudinary to pick a format the client can decode; the app's
/// HTTP client does not advertise AVIF, so it is sent JPEG, PNG or WebP. One
/// transformation component is inserted after `/image/upload/`, as its own
/// chained step, so any transformation already in the URL is untouched.
///
/// Left as it is: null or empty, anything not on res.cloudinary.com, anything
/// that is not an image upload, and a URL that already names a format (f_…).
String? deliverableImageUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  const marker = '/image/upload/';
  final at = url.indexOf(marker);
  if (at < 0 || !url.contains('res.cloudinary.com')) return url;
  final head = url.substring(0, at + marker.length);
  final rest = url.substring(at + marker.length);
  final firstSegment = rest.split('/').first;
  final namesAFormat =
      firstSegment.split(',').any((part) => part.startsWith('f_'));
  if (namesAFormat) return url;
  return '${head}f_auto/$rest';
}

/// [deliverableImageUrl] over a list, keeping non-strings (some payloads are
/// List<dynamic>) as they came.
List<T> deliverableImageUrls<T>(List<T> urls) => urls
    .map((u) => u is String ? deliverableImageUrl(u) as T : u)
    .toList();
