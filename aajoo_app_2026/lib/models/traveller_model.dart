/// A person an account books stays for, as /guest-profiles returns them.
///
/// `hasDocument` rather than a URL, deliberately. A government ID is never
/// served as a stored link: it lives in Cloudinary as an authenticated asset,
/// and reading one is a separate call that mints a signature valid for a few
/// minutes. Holding a URL on the model would mean holding one that expires.
class Traveller {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final int? age;

  /// male | female | other | unspecified
  final String gender;

  /// Aadhaar, Passport, Driving Licence, Voter ID, Other.
  final String? docType;
  final String? docNumber;
  final bool hasDocument;
  final String? docName;

  const Traveller({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.age,
    this.gender = 'unspecified',
    this.docType,
    this.docNumber,
    this.hasDocument = false,
    this.docName,
  });

  factory Traveller.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return Traveller(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fullName: (json['fullName'] ?? '').toString().trim(),
      phone: str(json['phone']),
      email: str(json['email']),
      age: int.tryParse(json['age']?.toString() ?? ''),
      gender: (json['gender'] ?? 'unspecified').toString(),
      docType: str(json['docType']),
      docNumber: str(json['docNumber']),
      hasDocument: json['hasDocument'] == true,
      docName: str(json['docName']),
    );
  }

  /// The one-line summary shown under the name in a list.
  String get summary {
    final bits = <String>[
      if (age != null) '$age yrs',
      if (gender != 'unspecified') gender,
      if (phone != null) phone!,
    ];
    return bits.isEmpty ? 'No other details' : bits.join(' · ');
  }
}
