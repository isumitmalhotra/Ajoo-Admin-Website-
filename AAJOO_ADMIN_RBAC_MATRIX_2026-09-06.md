# Admin RBAC — Endpoint × Role Matrix

Generated from the route definitions on 6 September 2026, not transcribed by
hand: every row is read out of `routes/*.js` and every cell is decided by
calling the same functions the middleware calls. If a gate changes, this file
changes with it.

**191 admin endpoints.** `200` means the role reaches it; `403` means the
server refuses; `no gate` marks the two endpoints that are deliberately
unauthenticated.

* `POST /admin/login` — the login itself.
* `POST /admin/create` — authorised inside the controller: it is open only
  while no admin exists at all, and demands a super-admin token from the second
  account onward.

**How the three narrower roles are confined.** 29 endpoints carry an explicit
`requireRole`; the remaining 162 were written when every administrator was
equivalent. Rather than gate them one by one — where the failure mode of
forgetting one is a role that reaches something it should not — `seo_manager`
and `support` are confined centrally in `adminAuth`/`adminAuthToken` against a
named list of what they MAY reach. A new endpoint is refused to both until
somebody chooses to add it.

`finance` and `admin` are not confined that way: `admin` is the operations
role, and `finance` is separated from it by the 27 explicit gates on the
finance routes — of which 8 are write-gated to `super_admin` and `finance`
alone, so an operations administrator cannot approve a payout.

---


#### Analytics

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/analytics/category-properties` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/analytics/graph` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/analytics/locations` | 200 | 200 | 200 | 403 | 403 |

#### Booking

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/booking/amend` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/booking/detail` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/booking/search` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/booking/status/list` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/booking/status/listing/admin-page` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/booking/status/update` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/booking/update` | 200 | 200 | 200 | 403 | 403 |

#### CMSSection

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/cms/faq-page/get` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/faq-page/update` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/cms/FaqPage/get` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/FaqPage/update` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/homepage/delete/image` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/cms/homepage/get` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/cms/homepage/property/dropdown` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/cms/homepage/testimonial/dropdown` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/homepage/update` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/section/add` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/section/search` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/cms/tc-page/get` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/tc-page/update` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/cms/TCPage/get` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/TCPage/update` | 200 | 200 | 200 | 403 | 200 |

#### Contact

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/contact/delete` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/contact/messages` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/contact/status` | 200 | 200 | 200 | 200 | 403 |

#### Coupons

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/coupon/add` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/coupon/delete` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/coupon/detail` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/coupon/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/coupon/status/update` | 200 | 200 | 200 | 403 | 403 |

#### FAQ

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/faq/add` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/faq/delete` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/faq/detail` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/faq/listing` | 200 | 200 | 200 | 403 | 200 |

#### Finance

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/finance/dashboard` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/finance/invoice/:invoiceId` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/finance/invoice/:invoiceId/download` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/invoice/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/invoice/void/:invoiceId` | 200 | 403 | 200 | 403 | 403 |
| `GET /admin/finance/ledger/:ledgerId` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/ledger/export` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/ledger/host/:hostId` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/ledger/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/ledger/user/:userId` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/finance/payout/:payoutId` | 200 | 200 | 200 | 403 | 403 |
| `PUT /admin/finance/payout/:payoutId/approve` | 200 | 403 | 200 | 403 | 403 |
| `PUT /admin/finance/payout/:payoutId/reject` | 200 | 403 | 200 | 403 | 403 |
| `POST /admin/finance/payout/initiate` | 200 | 403 | 200 | 403 | 403 |
| `PUT /admin/finance/payout/schedule/:scheduleId` | 200 | 403 | 200 | 403 | 403 |
| `POST /admin/finance/payout/schedule/create` | 200 | 403 | 200 | 403 | 403 |
| `POST /admin/finance/payout/schedule/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/payout/search` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/finance/reconciliation/:reconId` | 200 | 200 | 200 | 403 | 403 |
| `PUT /admin/finance/reconciliation/:reconId/resolve` | 200 | 403 | 200 | 403 | 403 |
| `POST /admin/finance/reconciliation/run` | 200 | 403 | 200 | 403 | 403 |
| `POST /admin/finance/reconciliation/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/reports/cashflow` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/reports/commission` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/reports/export` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/reports/revenue` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/finance/reports/tax` | 200 | 200 | 200 | 403 | 403 |

#### Host

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/host/detail/:hostId` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/host/kyc/approve` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/host/kyc/detail/:hostId` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/host/kyc/reject` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/host/payout/history` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/host/payout/hold` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/host/payout/release` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/host/performance/summary` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/host/search` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/host/search/assign-property` | 200 | 200 | 200 | 200 | 403 |

#### PropAnalytics

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/properties/analytic/search` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/property/analytic/detail` | 200 | 200 | 200 | 200 | 403 |

#### Property

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/properties/delete/image` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/properties/search` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/properties/update-status` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/properties/verify` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/property` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/property/create` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/property/delete` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/property/nearby` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/property/nearby/save` | 200 | 200 | 200 | 403 | 403 |

#### PropertyAmeneties

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/amenity` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/amenity/create` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/amenity/delete` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/amenity/list/dropdowns` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/amenity/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/amenity/update-status` | 200 | 200 | 200 | 403 | 403 |

#### PropertyCategories

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/categories` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/categories/delete` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/category` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/category/:categoryId/flow` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/category/create` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/category/flow` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/category/list/dropdowns` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/category/update-status` | 200 | 200 | 200 | 403 | 403 |

#### PropertyReviews

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/property/review/detail` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/property/review/search` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/property/review/update` | 200 | 200 | 200 | 403 | 403 |

#### PropertyTag

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/tag/create` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/tag/delete` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/tag/listing/dropdowns` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/tag/search` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/tag/single` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/tag/update-status` | 200 | 200 | 200 | 403 | 403 |

#### Redirects

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/seo/redirects` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/redirects` | 200 | 200 | 200 | 403 | 200 |
| `DELETE /admin/seo/redirects/:id` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/redirects/analyse` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/redirects/export` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/redirects/import` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/slug-history` | 200 | 200 | 200 | 403 | 200 |

#### Seo

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/seo/bulk/apply` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/bulk/export` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/bulk/import` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/bulk/import/apply` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/bulk/preview` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/bulk/variables` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/changes` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/global` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/global` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/health` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/images` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/images` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/images/bulk/apply` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/images/bulk/preview` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/page` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/page` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/robots/preview` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/sitemap` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/sitemap/regenerate` | 200 | 200 | 200 | 403 | 200 |
| `GET /admin/seo/templates` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/templates` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/seo/templates/preview` | 200 | 200 | 200 | 403 | 200 |

#### Support

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/support/tickets` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/support/tickets/:ticketId` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/support/tickets/reply` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/support/tickets/status` | 200 | 200 | 200 | 200 | 403 |

#### TermsAndCond

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/terms-condition/add` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/terms-condition/delete` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/terms-condition/detail` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/terms-condition/listing` | 200 | 200 | 200 | 403 | 200 |

#### User

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/user/create` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/user/delete` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/user/delete/image` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/user/search` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/user/single` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/user/update/status` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/user/verification` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/user/verify` | 200 | 200 | 200 | 403 | 403 |

#### blog

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/blog/delete` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/blog/listing` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/blog/status` | 200 | 200 | 200 | 403 | 200 |

#### cmsContent

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/cms/content/get` | 200 | 200 | 200 | 403 | 200 |
| `POST /admin/cms/content/save` | 200 | 200 | 200 | 403 | 200 |

#### core

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/analytics/summary` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/audit` | 200 | 403 | 403 | 403 | 403 |
| `GET /admin/bookings/analytics` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/boost/list` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/create` | no gate | no gate | no gate | no gate | no gate |
| `GET /admin/dashboard` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/disputes/list` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/disputes/resolve` | 200 | 200 | 200 | 200 | 403 |
| `POST /admin/login` | no gate | no gate | no gate | no gate | no gate |
| `POST /admin/logout` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/logs/list` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/members/list` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/members/role` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/members/status` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/negotiations/audit` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/negotiations/list` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/negotiations/messages` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/referrals/list` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/roles/list` | 200 | 200 | 200 | 200 | 200 |
| `GET /admin/verify-token` | 200 | 200 | 200 | 200 | 200 |

#### guestProfile

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/guest-profiles/:id/document` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/guest-profiles/for-booking/:bookingId` | 200 | 200 | 200 | 403 | 403 |

#### hostDues

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/host-dues` | 200 | 200 | 200 | 403 | 403 |

#### listingEngine

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `GET /admin/listing/detail/:propertyId` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/listing/queue` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/listing/review` | 200 | 200 | 200 | 403 | 403 |

#### mailTest

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/mail/test` | 200 | 200 | 200 | 403 | 403 |

#### notifications

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `PUT /admin/notifications/:id/read` | 200 | 200 | 200 | 200 | 403 |
| `GET /admin/notifications/search` | 200 | 200 | 200 | 200 | 403 |

#### property

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/properties/load` | 200 | 200 | 200 | 403 | 403 |

#### propertyOffers

| Endpoint | super_admin | admin | finance | support | seo_manager |
|---|---|---|---|---|---|
| `POST /admin/offers` | 200 | 200 | 200 | 403 | 403 |
| `GET /admin/offers` | 200 | 200 | 200 | 403 | 403 |
| `POST /admin/offers/:id/end` | 200 | 200 | 200 | 403 | 403 |
