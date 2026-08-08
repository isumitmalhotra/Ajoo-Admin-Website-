import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';

class TermsBottomSheet extends StatelessWidget {
  final VoidCallback onAgreed;

  const TermsBottomSheet({super.key, required this.onAgreed});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ListView(
          controller: scrollController,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.info_outline, color: kprimaryColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Terms & Conditions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Sections ─────────────────────────────────────────────────────
            _section('1. Property Listing Agreement'),
            _bullet('By listing your property, you agree to provide accurate and up-to-date information.'),
            _bullet('You confirm that you have the legal right to rent out this property.'),
            _bullet('All photos and descriptions must be genuine and current.'),

            _section('2. Host Responsibilities'),
            _bullet('Maintain property in clean and safe condition for guests.'),
            _bullet('Respond to booking requests within 24 hours.'),
            _bullet('Provide accurate check-in/check-out instructions.'),
            _bullet('Honor confirmed bookings and pricing agreements.'),

            _section('3. Platform Commission'),
            _commissionBanner(),
            const SizedBox(height: 8),
            _bullet('Your first 5 property listings are completely commission-free.'),
            _bullet('After 5 properties, a 12% commission applies to all confirmed bookings.'),
            _bullet('Commission is automatically deducted from booking payments.'),
            _bullet('No hidden charges - transparent and fair fee structure.'),
            _bullet('Commission helps maintain platform quality and support services.'),

            _section('4. Property Standards'),
            _bullet('Property must meet basic safety and hygiene standards.'),
            _bullet('Essential amenities (water, electricity, security) must be functional.'),
            _bullet('Property should match the category and description provided.'),

            _section('5. Cancellation Policy'),
            _bullet('Hosts can set their own cancellation policies (flexible, moderate, strict).'),
            _bullet('Frequent cancellations may result in listing penalties or removal.'),
            _bullet('Force majeure events are handled case-by-case.'),

            _section('6. Guest Relations'),
            _bullet('Treat all guests with respect and professionalism.'),
            _bullet('Do not discriminate based on race, religion, gender, or nationality.'),
            _bullet('Address guest concerns promptly and fairly.'),

            _section('7. Verification & Documentation'),
            _bullet('Complete KYC verification is mandatory for all hosts.'),
            _bullet('Property ownership or rental agreement documents may be required.'),
            _bullet('Regular verification updates may be requested.'),

            _section('8. Liability & Insurance'),
            _bullet('Hosts are responsible for property damage not covered by guest deposits.'),
            _bullet('Platform recommends having property insurance coverage.'),
            _bullet('Platform is not liable for property damage or theft.'),

            _section('9. Content & Privacy'),
            _bullet('Platform can use property photos for marketing purposes.'),
            _bullet('Guest personal information must be kept confidential.'),
            _bullet('Reviews and ratings are public and cannot be manipulated.'),

            _section('10. Compliance & Penalties'),
            _bullet('Violations may result in listing suspension or account termination.'),
            _bullet('False information or fake reviews will result in immediate removal.'),
            _bullet("Legal compliance with local rental laws is host's responsibility."),

            const SizedBox(height: 20),
            _agreementSummary(),
            const SizedBox(height: 20),

            // ── CTAs ─────────────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onAgreed();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('I Understand & Agree'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kprimaryColor,
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          ],
        ),
      );

  Widget _commissionBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSuccess.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kSuccess.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.local_offer, color: kSuccess, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Special Offer: First 5 properties are commission-free!',
                style: TextStyle(
                  color: kSuccess,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _agreementSummary() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kprimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kprimaryColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.handshake, color: kprimaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Agreement Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kprimaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Wrap(
                children: [
                  const Icon(Icons.star, color: kSuccess, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'First 5 properties: 0% commission',
                    style: TextStyle(
                        color: kSuccess,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'After 5 properties: 12% commission',
                    style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'By checking the agreement box, you confirm that you have read, understood, and agree to abide by all the terms and conditions listed above. This creates a legally binding agreement between you and the platform.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
}
