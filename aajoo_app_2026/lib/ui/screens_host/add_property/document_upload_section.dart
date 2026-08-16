import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/constants.dart';

class DocumentUploadSection extends StatelessWidget {
  final String stateText;
  final XFile? fireAndSafetyNOC;
  final XFile? jamaBandhiDoc;
  final XFile? nocDocument;
  final XFile? policeVerificationDoc;
  final bool isPartySelected;
  final XFile? partyLicenseDoc;
  final ValueChanged<String> onPick;

  const DocumentUploadSection({
    super.key,
    required this.stateText,
    required this.fireAndSafetyNOC,
    required this.jamaBandhiDoc,
    required this.nocDocument,
    required this.policeVerificationDoc,
    required this.isPartySelected,
    required this.partyLicenseDoc,
    required this.onPick,
  });

  /// Total number of documents uploaded
  int get uploadedCount =>
      (fireAndSafetyNOC != null ? 1 : 0) +
      (jamaBandhiDoc != null ? 1 : 0) +
      (nocDocument != null ? 1 : 0) +
      (policeVerificationDoc != null ? 1 : 0);

  bool get _isHimachal => stateText.trim().toLowerCase().contains('himachal');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tiles ─────────────────────────────────────────────────────────────
        _DocumentTile(
          title: 'Fire and Safety NOC',
          file: fireAndSafetyNOC,
          subtitle: 'Fire and safety clearance certificate',
          isUploaded: fireAndSafetyNOC != null,
          onTap: () => onPick('fireAndSafety'),
        ),
        const SizedBox(height: 8),

        // Jama Bandhi — Himachal Pradesh only
        if (_isHimachal && !isPartySelected) ...[
          _DocumentTile(
            title: 'Jama Bandhi Document',
          file: jamaBandhiDoc,
            subtitle:
                'Property registration or ownership document (Himachal Pradesh only)',
            isUploaded: jamaBandhiDoc != null,
            onTap: () => onPick('jamaBandhi'),
          ),
          const SizedBox(height: 8),
        ],

        // Jama Bandhi — Himachal Pradesh only
        if (isPartySelected) ...[
          _DocumentTile(
            title: 'Party License Document',
          file: partyLicenseDoc,
            subtitle: 'Party license document (for party properties only)',
            isUploaded: partyLicenseDoc != null,
            onTap: () => onPick('partyLicense'),
          ),
          const SizedBox(height: 8),
        ],

        _DocumentTile(
          title: 'NOC Document',
          file: nocDocument,
          subtitle: 'No Objection Certificate',
          isUploaded: nocDocument != null,
          onTap: () => onPick('noc'),
        ),
        const SizedBox(height: 8),

        _DocumentTile(
          title: 'Police Verification Document',
          file: policeVerificationDoc,
          subtitle: 'Police clearance certificate',
          isUploaded: policeVerificationDoc != null,
          onTap: () => onPick('policeVerification'),
        ),

        // ── Status text ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            uploadedCount < 3
                ? 'Please upload at least 3 documents ($uploadedCount/3)'
                : '✓ Documents uploaded ($uploadedCount/3)',
            style: TextStyle(
              color: uploadedCount < 3 ? kDanger : kSuccess,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Single document tile ──────────────────────────────────────────────────────

class _DocumentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isUploaded;
  final VoidCallback onTap;

  /// The picked file, for the thumbnail. A green tick says "something was
  /// selected"; only a picture of the document says it was the RIGHT one.
  final XFile? file;

  const _DocumentTile({
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.onTap,
    this.file,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: isUploaded && file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(file!.path),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    // A non-image document keeps the tick instead of an error.
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.check_circle, color: kSuccess),
                  ),
                )
              : Icon(
                  isUploaded ? Icons.check_circle : Icons.upload_file,
                  color: isUploaded ? kSuccess : kMuted,
                ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isUploaded ? 'Selected — tap to replace' : subtitle,
            style: TextStyle(
              color: isUploaded ? kSuccess : kMuted,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      );
}
