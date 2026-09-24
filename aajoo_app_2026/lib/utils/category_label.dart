/// One place that turns whatever the API sent for a category into a name.
///
/// The backend has two shapes, both deliberate:
///
///   * `category_titles` on the list and search payloads — plain strings.
///   * `categories` on the property detail payload — full records,
///     `{cat_id: 2, cat_title: Resort, cat_slug: resort}`.
///
/// Several call sites mapped whichever they had through `.toString()`, and on
/// the second shape that prints the whole record. The tester photographed
/// `{cat_id: 2, cat_title: Resort, cat_slug: resort}` sitting over the hero
/// image of a listing, and the model layer does the same `.toString()` on the
/// way in — so once a record has been flattened that way, the literal is a
/// plain String and no `is Map` check downstream can rescue it.
///
/// This handles all three: a record, a name, and a record that has already
/// been stringified by somebody else.
library;

/// Matches a Dart `Map.toString()` that carries a `cat_title`.
final RegExp _stringifiedRecord = RegExp(r'cat_title:\s*([^,}]+)');

/// The display name for one category, or null when there is not one.
String? categoryLabel(dynamic raw) {
  if (raw == null) return null;

  if (raw is Map) {
    final t = (raw['cat_title'] ?? raw['title'] ?? raw['name'] ?? '')
        .toString()
        .trim();
    return t.isEmpty ? null : t;
  }

  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  // Already flattened by a `.toString()` further up. Recover the name rather
  // than printing the record at a guest.
  if (s.startsWith('{') && s.contains('cat_title')) {
    final m = _stringifiedRecord.firstMatch(s);
    final t = m?.group(1)?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // A bare record with no usable name is not a label.
  if (s.startsWith('{') && s.endsWith('}')) return null;

  return s;
}

/// Display names for a list of categories, in order, with the unusable dropped.
List<String> categoryLabels(dynamic raw) {
  if (raw == null) return const <String>[];
  final items = raw is List ? raw : <dynamic>[raw];
  final out = <String>[];
  for (final item in items) {
    final label = categoryLabel(item);
    if (label != null) out.add(label);
  }
  return out;
}
