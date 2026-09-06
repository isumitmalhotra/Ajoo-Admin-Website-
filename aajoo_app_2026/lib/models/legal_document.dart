/// A legal document served by the backend — `GET /legal/document/:key`.
///
/// The text is NOT bundled with the app. The Host Agreement's Developer
/// Requirements say the host must read the agreement before publishing, and an
/// agreement that says one thing in the app and another on the website is not
/// one agreement. This platform already has three different privacy policies
/// from each surface keeping its own copy; the legal suite will not repeat it.
class LegalBlock {
  /// 'p' for a paragraph, 'ul' for a bullet list.
  final String type;
  final String? text;
  final List<String> items;

  const LegalBlock({required this.type, this.text, this.items = const []});

  static LegalBlock? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final t = raw['t']?.toString();
    if (t == 'p') {
      final v = raw['v']?.toString();
      return (v == null || v.trim().isEmpty) ? null : LegalBlock(type: 'p', text: v);
    }
    if (t == 'ul') {
      final v = raw['v'];
      if (v is! List || v.isEmpty) return null;
      return LegalBlock(type: 'ul', items: v.map((e) => e.toString()).toList());
    }
    return null;
  }
}

class LegalSection {
  /// 0 is the parties block, which carries no clause number.
  final int number;
  final String title;
  final List<LegalBlock> blocks;

  const LegalSection({required this.number, required this.title, required this.blocks});

  static LegalSection? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final blocks = <LegalBlock>[];
    final list = raw['blocks'];
    if (list is List) {
      for (final b in list) {
        final parsed = LegalBlock.fromJson(b);
        if (parsed != null) blocks.add(parsed);
      }
    }
    if (blocks.isEmpty) return null;
    return LegalSection(
      number: int.tryParse('${raw['n']}') ?? 0,
      title: raw['title']?.toString() ?? '',
      blocks: blocks,
    );
  }
}

class LegalDocument {
  final String key;
  final String title;
  final String version;
  final String effectiveDate;

  /// The exact wording the checkbox must show, from the server. Retyping it
  /// here would make the app ask for a subtly different consent.
  final String acceptanceStatement;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.key,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.acceptanceStatement,
    required this.sections,
  });

  static LegalDocument? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final list = raw['sections'];
    if (list is! List || list.isEmpty) return null;
    final sections = <LegalSection>[];
    for (final s in list) {
      final parsed = LegalSection.fromJson(s);
      if (parsed != null) sections.add(parsed);
    }
    if (sections.isEmpty) return null;
    return LegalDocument(
      key: raw['key']?.toString() ?? '',
      title: raw['title']?.toString() ?? 'Agreement',
      version: raw['version']?.toString() ?? '',
      effectiveDate: raw['effectiveDate']?.toString() ?? '',
      acceptanceStatement: raw['acceptanceStatement']?.toString() ?? '',
      sections: sections,
    );
  }
}

/// A document this host still owes, from `GET /host/legal/status`.
class OutstandingLegal {
  final String key;
  final String title;
  final String version;
  final String effectiveDate;

  /// They accepted an EARLIER version and a material update has been published.
  /// A host who has never accepted is asked at the publish step instead.
  final bool previouslyAccepted;

  const OutstandingLegal({
    required this.key,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.previouslyAccepted,
  });

  static OutstandingLegal? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final key = raw['key']?.toString();
    if (key == null || key.isEmpty) return null;
    return OutstandingLegal(
      key: key,
      title: raw['title']?.toString() ?? 'Agreement',
      version: raw['version']?.toString() ?? '',
      effectiveDate: raw['effectiveDate']?.toString() ?? '',
      previouslyAccepted: raw['previouslyAccepted'] == true,
    );
  }
}
