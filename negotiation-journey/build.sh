#!/usr/bin/env bash
# Regenerate the client PDF from the markdown and the shots.
set -e
cd "$(dirname "$0")/.."
PDF_SUBTITLE="Every scenario in the negotiation engine, photographed on the live site after the 12 September rebuild &mdash; what the guest sees and what the host sees, side by side." \
PDF_EYEBROW="Aajoo Homes &mdash; Negotiation engine" \
PDF_PREPARED="Prepared 12 September 2026 by the Zyphex Tech development team" \
PDF_VERIFIED="Every screen photographed on www.aajoohomes.com, driving the live flow with a real guest and a real host account" \
PDF_FOOTER="Aajoo Homes &mdash; Negotiation engine: user journey" \
node scripts/build-uat-pdf.mjs \
  "$(pwd)/negotiation-journey/NEGOTIATION_JOURNEY.md" \
  "$(pwd)/negotiation-journey/Aajoo-Negotiation-User-Journey.pdf"
