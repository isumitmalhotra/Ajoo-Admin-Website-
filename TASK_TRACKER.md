# AAJOO Homes — Project Task Tracker

> **Project:** AAJOO Homes – Platform, Finance & Host Systems Enhancements  
> **Client:** AAJOO Homes Private Limited  
> **Service Provider:** Zyphex Technologies  
> **Total Investment:** ₹1,60,000  
> **Total Duration:** 10–12 Weeks  
> **Contract Date:** February 11, 2026  
> **Last Audit:** March 14, 2026

---

## Status Legend

| Symbol | Meaning            |
|--------|--------------------|
| ⬜     | Not Started        |
| 🔄     | In Progress        |
| ✅     | Completed (by prev team / already exists) |
| 🔴     | Blocked / Needs Client Input |

---

## Payment Milestones

| # | Milestone             | Trigger                          | %   | Amount   | Status |
|---|-----------------------|----------------------------------|-----|----------|--------|
| 1 | Project Kickoff       | Proposal signed + project start  | 30% | ₹48,000  | ✅     |
| 2 | Dev & Design Complete | M2 & M3 achieved (Weeks 5–7)    | 40% | ₹64,000  | ⬜     |
| 3 | Go-Live               | M5 achieved – production (Wk 10) | 30% | ₹48,000  | ⬜     |

---

## Project Milestones

| # | Milestone              | Target Week | Deliverable                                          | Status |
|---|------------------------|-------------|------------------------------------------------------|--------|
| M1 | Design Sign-off       | Week 2      | Architecture document, requirements approval         | ⬜     |
| M2 | Development Build     | Week 5      | Feature implementation, development testing          | ⬜     |
| M3 | Specification Complete | Week 7      | Finance & Host system designs, implementation roadmap | ⬜     |
| M4 | UAT Sign-off          | Week 9      | All features tested, UAT approval                    | ⬜     |
| M5 | Production Go-Live    | Week 10     | Live deployment, support begins                      | ⬜     |
| M6 | Support Complete      | Week 14     | 30 days of support, knowledge transfer               | ⬜     |

---

---

# CODEBASE AUDIT — What Already Exists (as of March 10, 2026)

> This section documents everything found in the codebase before our work begins.  
> Features marked ✅ are already built and working. Features marked ⚠️ are partial/stubbed.

## ✅ Fully Built & Working

### Admin Panel
| Feature | Files/Location | What Works |
|---------|---------------|------------|
| Admin Login | `src/pages/admin/adminLogin/` | JWT auth, token in localStorage, 401 interceptor |
| Admin Dashboard | `src/pages/admin/admindashboard/` | Stats cards (users/hosts/properties/bookings), monthly booking chart, daily user chart, latest tables |
| User Management | `src/pages/admin/userPage/` | Full CRUD — add/edit/delete modals, search, pagination, role selector, profile upload, ID upload |
| Property Management | `src/pages/admin/properties/` | Full CRUD — create/edit form, status toggle, delete, image management, filtering |
| Property Categories | `src/pages/admin/` | Full CRUD with dropdown support |
| Property Tags | `src/pages/admin/` | Full CRUD with dropdown support |
| Property Amenities | `src/pages/admin/` | Full CRUD with dropdown support |
| Property Verification | `src/pages/admin/property-verifications/` | Dedicated verification page |
| Booking Management | `src/pages/admin/adminBooking/` | View bookings, detail modal, update status, search |
| Booking Status | `src/pages/admin/status/` | Status listing, update status |
| Property Reviews | `src/pages/admin/property-reviews/` | View/edit reviews, search, filtering |
| Admin Layout | `src/components/admin/adminLayout/` | Sidebar + Navbar + Content area |
| Admin Charts | `src/components/admin/charts/` | Bar, Line, Pie, Gauge, SparkLine charts |
| Admin Tables | `src/components/admin/adminTable/` | Reusable User/Property/Booking tables |
| Pagination | `src/components/admin/Pagination/` | Reusable pagination component |

### User/Guest Frontend
| Feature | Files/Location | What Works |
|---------|---------------|------------|
| Home Page | `src/pages/user/home.tsx` | Map with filters, featured properties, categories, FAQs, CTAs |
| Property Listing | `src/pages/user/PropertyListing.tsx` | Search, sidebar filters, property grid, map view |
| Property Detail | `src/pages/user/PropertyDetail.tsx` | Gallery, booking box, map, reviews |
| Booking Flow | `FinalBookingPage.tsx` → `UserCheckoutPage.tsx` → `BookingConfirmed.tsx` | Full checkout → Razorpay → confirmation |
| Booking Cancellation | `src/pages/user/CancelBookResult.tsx` | Cancellation result page |
| User Dashboard | `src/pages/user/dashboard.tsx` + `DashboardLayout.tsx` | Profile area with sidebar |
| User Bookings | `src/pages/user/UserBookings.tsx` | Booking history |
| Ongoing Bookings | `src/pages/user/userOngoingBooking.tsx` | Active bookings with floating UI |
| User Profile | `src/pages/user/UserProfile.tsx` | Profile settings |
| User Transactions | `src/pages/user/UserTransactions.tsx` | Transaction history view |
| About Us | `src/pages/user/AboutUs.tsx` | Static page |
| Contact Us | `src/pages/user/ContactUs.tsx` | Static page |
| FAQ | `src/pages/user/FAQ.tsx` | Static page |
| Help Center | `src/pages/user/HelpCenter.tsx` | Static page |
| Terms & Conditions | `src/pages/user/TermsAndConditions.tsx` | Static page |
| Privacy Policy | `src/pages/user/PrivacyPolicyPage.tsx` | Static page |
| State Regulations | `src/pages/user/StateRegulation.tsx` | Static page |
| Why Host With Us | `src/pages/user/WhyHostsListWithAajoo.tsx` | Static page |
| 404 Page | `src/pages/user/NotFound.tsx` | Error page |

### Authentication
| Feature | Files/Location | What Works |
|---------|---------------|------------|
| User Login | `src/auth/Login.tsx` + `Forms/LoginForm.tsx` | Login form with validation |
| User Signup | `src/auth/UserSignup.tsx` | 3-step: Personal → Address → ID upload |
| OTP Verification | `src/auth/SignupOtpVerification.tsx` + `VerifyOtp.tsx` | OTP verification flow |
| Forgot Password | `src/auth/ForgotPassword.tsx` + `Forms/ForgotForm.tsx` | Initiate reset |
| Reset Password | `src/auth/ResetPassword.tsx` + `Forms/ResetPasswordFrom.tsx` | Set new password |

### Frontend Components
| Feature | Files/Location | What Works |
|---------|---------------|------------|
| Razorpay Payment | `src/components/frontend/RazorpayPayment.tsx` | Payment component exists |
| Map & Filters | `src/components/frontend/MapandFilter.tsx` | Map with filter integration |
| Property Cards | `src/components/frontend/HomePropCard.tsx` | Property card display |
| Property Gallery | `src/components/frontend/PropertyGallery.tsx` | Image gallery |
| Review Slider | `src/components/frontend/ReviewSlider.tsx` | Carousel for reviews |
| Sidebar Filters | `src/components/frontend/SidebarFilters.tsx` | Filter sidebar |
| Booking Modals | `src/components/frontend/modals/` | BookingDetails, CancellationPolicy, HostDetails, OngoingBooking |
| Header/Footer | `src/components/layout/Header.tsx`, `Footer.tsx` | Global nav + footer |
| User Sidebar | `src/components/layout/UserSidebar.tsx` | Dashboard sidebar |

### State Management (Redux — ~45+ slices)
| Area | Slices | Status |
|------|--------|--------|
| Admin Auth | `adminAuth` — Login, token, logout | ✅ |
| User Auth | `authSllice.tsx` — login, getUser, forgotPassword, verifyOtp, resetPassword | ✅ |
| User Mgmt | `users`, `userDetails`, `userAddUpdate`, `userDelete`, `userImageDelete`, `userStatusUpdate` | ✅ |
| Host Mgmt | `hosts`, `hostForProperty` — list + property assignment | ✅ |
| Properties | `properties`, `propertyDetails`, `propertyAddUpdate`, `propertyStatus`, `propertyDelete`, `propertyById`, `deletePropertyImage` | ✅ |
| Categories | `propertyCategory`, `propertyCategoryDetails`, `propertyCategoryAddUpdate`, `propertyCategoryStatus`, `propertyCategoryDelete`, `categoryDropdown` | ✅ |
| Tags | `propertyTag`, `propertyTagDetails`, `propertyTagAddUpdate`, `propertyTagStatus`, `propertyTagDelete`, `tagsDropdown` | ✅ |
| Amenities | `propertyAmenity`, `propertyAmenityDetails`, `propertyAmenityAddUpdate`, `propertyAmenityStatus`, `propertyAmenityDelete`, `amenitiesDropdown` | ✅ |
| Bookings | `bookingList`, `bookingDetail`, `bookingStatus`, `updateBookingStatus`, `bookingStatusListingForAdminPage`, `updateBookingStatusAdminPage` | ✅ |
| Dashboard | `adminDashboardSlice` | ✅ |
| UI | `ui` — global UI state | ✅ |

### APIs Configured (`src/services/endpoints.ts`) — ~41 endpoints
| Area | Count | Status |
|------|-------|--------|
| Admin Auth | 2 | ✅ |
| User Management | 6 | ✅ |
| Host Management | 3 | ✅ |
| Property Categories | 6 | ✅ |
| Property Tags | 6 | ✅ |
| Property Amenities | 6 | ✅ |
| Properties | 6 | ✅ |
| Bookings | 6 | ✅ |

---

## ⚠️ Partially Done / Stub Only

| Feature | What Exists | What's Missing |
|---------|------------|----------------|
| **Admin Settings** | Route at `/admin/settings` renders `<h1>Settings</h1>` only | Entire settings UI — site config, notification settings, role permissions, system preferences |
| **Host Dashboard** | `src/pages/host/dashboard.tsx` renders `<h1>Host Dashboard</h1>` only | Entire host portal — earnings, metrics, properties, bookings, payouts |
| **Admin Host Management** | `src/pages/admin/host-management/` has basic list page | No host detail view, no KYC review, no host performance analytics, no payout management |
| **Admin Notifications** | `AdminNotifySidebar.tsx` is MUI template with dummy items (`Inbox, Starred, Drafts`) | No real notification data, no backend integration, no notification types |
| **Become a Host Page** | Home page has link to `/become-a-host` | Page/route does NOT exist — throws 404 |
| **Property Reviews (User)** | Admin can manage reviews | User-side review submission may be incomplete |

---

## ❌ Not Built At All (New Work Required)

| Feature | Contract Phase | Priority |
|---------|---------------|----------|
| Finance Management System — Ledger Management | Phase 4 | HIGH |
| Finance Management System — Payout Processing | Phase 4 | HIGH |
| Finance Management System — Reconciliation | Phase 4 | HIGH |
| Finance Management System — Reports & Analytics | Phase 4 | HIGH |
| Finance Management System — Invoice Generation | Phase 4 | HIGH |
| Finance Management System — Finance Dashboard (Admin) | Phase 4 | HIGH |
| Host Management System — Host Onboarding / KYC Flow | Phase 4 | HIGH |
| Host Management System — Host Profile Management | Phase 4 | HIGH |
| Host Management System — Performance Metrics | Phase 4 | HIGH |
| Host Management System — Host Payout Management | Phase 4 | HIGH |
| Host Management System — Communication / Messaging | Phase 4 | HIGH |
| Host Management System — Host Portal (full) | Phase 4 | HIGH |
| RBAC (Fine-grained roles: Admin, Finance, Host, Support, Guest) | Phase 2 | MEDIUM |
| Audit Trail / Financial operation logging | Phase 2 | MEDIUM |
| Advanced Analytics & Reporting suite | Phase 3/4 | MEDIUM |

---

## 🛠️ Code Quality Issues Found

| Issue | File | Fix Needed |
|-------|------|-----------|
| Typo in filename | `src/redux/authSllice.tsx` | Rename to `authSlice.tsx` |
| Inconsistent naming | Mix of camelCase and PascalCase in filenames | Standardize naming |
| Commented-out code | Auth and store files have dead code | Clean up |
| Placeholder notification | `AdminNotifySidebar.tsx` has MUI demo code | Replace with real implementation |
| Missing route | `/become-a-host` linked but no page exists | Create page or remove link |

---

---

# STEP 0 — Immediate Fixes & Quick Wins (Before Phase Work)

> Do these first. They fix broken things in the existing website.

| # | Task | Status | Files Involved | Priority |
|---|------|--------|---------------|----------|
| 0.1 | **Build "Become a Host" page** — home page links to `/become-a-host` but page doesn't exist (404) | ⬜ | Create `src/pages/user/BecomeAHost.tsx`, add route in `App.tsx` | HIGH |
| 0.2 | **Build Admin Settings page** — currently just `<h1>Settings</h1>` stub | ⬜ | Create `src/pages/admin/settings/`, update route in `App.tsx` | HIGH |
| 0.3 | **Replace dummy Admin Notifications** — sidebar has fake MUI placeholder data | ⬜ | `src/components/admin/adminNotification/AdminNotifySidebar.tsx` | MEDIUM |
| 0.4 | **Build Host Dashboard** — currently just `<h1>Host Dashboard</h1>` stub | ⬜ | `src/pages/host/dashboard.tsx` | HIGH |
| 0.5 | **Fix filename typo** — `authSllice.tsx` → `authSlice.tsx` (and update all imports) | ⬜ | `src/redux/authSllice.tsx` + all importing files | LOW |
| 0.6 | **Clean up dead/commented-out code** in auth and store files | ⬜ | `src/app/store.ts`, auth files | LOW |
| 0.7 | **Verify Razorpay integration** — component exists but integration depth unknown | ⬜ | `src/components/frontend/RazorpayPayment.tsx` | MEDIUM |
| 0.8 | **Verify user review submission** — admin side works, user submission unclear | ⬜ | Frontend review components | MEDIUM |

---

# PHASE 1 — Discovery & Solution Design (Weeks 1–2)

**Duration:** 5–7 business days  
**Approval Gate:** Client sign-off on architecture and requirements

### 1.1 Requirements Review
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.1.1 | Detailed walkthrough of PRD with product and operations teams | ⬜ | |
| 1.1.2 | Refine feature specifications based on PRD review | ⬜ | |
| 1.1.3 | Requirements sign-off document | ⬜ | |

### 1.2 User Journey Mapping
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.2.1 | Document flows for Guests | ⬜ | |
| 1.2.2 | Document flows for Hosts | ⬜ | |
| 1.2.3 | Document flows for Admins | ⬜ | |
| 1.2.4 | Document flows for Finance Team | ⬜ | |
| 1.2.5 | Document flows for Support Staff | ⬜ | |

### 1.3 Domain Modeling
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.3.1 | Define core entities: Bookings, Payouts, Invoices, Hosts, Transactions, Users | ⬜ | Bookings & Users already modeled, Payouts/Invoices/Ledgers are new |
| 1.3.2 | Entity-relationship diagrams | ⬜ | |

### 1.4 Architecture Planning
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.4.1 | High-level system design for current and future modules | ⬜ | |
| 1.4.2 | Low-level system design for current and future modules | ⬜ | |
| 1.4.3 | Architecture documents | ⬜ | |

### 1.5 Data Security Assessment
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.5.1 | Identify security zones and access controls | ⬜ | Current: basic JWT admin auth only |
| 1.5.2 | Define data sensitivity levels | ⬜ | |
| 1.5.3 | Security matrix document | ⬜ | |

### 1.6 Integration Mapping
| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.6.1 | Map integration points: Mobile Apps | ⬜ | |
| 1.6.2 | Map integration points: Web Portal | ⬜ | Existing routes documented above |
| 1.6.3 | Map integration points: Admin Dashboard | ⬜ | ~41 endpoints already built |
| 1.6.4 | Map integration points: Payments (Razorpay) | ⬜ | RazorpayPayment.tsx exists, needs verification |
| 1.6.5 | Map integration points: Notifications (Firebase FCM) | ⬜ | Currently placeholder only |
| 1.6.6 | Integration flowcharts | ⬜ | |

### Phase 1 Deliverables
| # | Deliverable | Status |
|---|-------------|--------|
| D1.1 | Solution Architecture Document (Part A implementation scope) | ⬜ |
| D1.2 | Preliminary architecture for Finance Management & Host Management Systems (Part B) | ⬜ |
| D1.3 | Requirements sign-off document | ⬜ |
| D1.4 | Security and access control matrix | ⬜ |

---

# PHASE 2 — Backend Development & Integrations (Weeks 3–5)

**Duration:** 10–12 business days  
**Checkpoint:** Development build review with technical team  
**Note:** This repo is FRONTEND only. Backend work happens in a separate repo. Tasks here relate to API contracts and frontend integration.

### 2.1 API Design & Development
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.1.1 | Design REST endpoints for FMS features | ⬜ | NEW — no finance endpoints exist |
| 2.1.2 | Design REST endpoints for HMS features | ⬜ | NEW — only basic host search/status exists |
| 2.1.3 | Design REST endpoints for enhanced admin features | ⬜ | Settings, notifications, analytics |
| 2.1.4 | API Documentation (OpenAPI/Swagger format) | ⬜ | |
| 2.1.5 | Existing endpoints — review & verify | ✅ | 41 endpoints already configured in `endpoints.ts` |

### 2.2 Database Schema Updates
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.2.1 | Extend data models for current features | ⬜ | Backend work |
| 2.2.2 | Design FMS data models (Ledger, PayoutSchedule, Invoice, ReconciliationRecord) | ⬜ | NEW |
| 2.2.3 | Design HMS data models (Host, HostProfile, HostPerformance, PayoutAccount, CommunicationLog) | ⬜ | NEW |
| 2.2.4 | Migration scripts | ⬜ | Backend work |

### 2.3 Third-Party Integrations
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.3.1 | Verify & enhance Razorpay payment gateway integration | 🔄 | Component exists, depth unclear |
| 2.3.2 | Real notification services integration (Firebase FCM) | ⬜ | Currently placeholder only |
| 2.3.3 | Analytics integration | ⬜ | |

### 2.4 Authentication & Authorization
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.4.1 | Existing admin JWT auth | ✅ | Working — `adminToken` in localStorage, 401 interceptor |
| 2.4.2 | Existing user auth (login, signup, OTP, reset) | ✅ | Full flow working |
| 2.4.3 | RBAC — add Finance, Host, Support roles alongside Admin & Guest | ⬜ | NEW — currently only Admin role exists |
| 2.4.4 | JWT refresh token rotation | ⬜ | Currently only basic token, no refresh |

### 2.5 Business Logic Implementation
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.5.1 | Core logic for booking flows | ✅ | Existing booking flow works |
| 2.5.2 | Payout calculations | ⬜ | NEW |
| 2.5.3 | Reconciliation foundations | ⬜ | NEW |

### 2.6 Data Validation & Security
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.6.1 | Input validation | 🔄 | Yup/Zod schemas exist for existing forms; need new ones for FMS/HMS |
| 2.6.2 | Encryption (HTTPS, AES-256 at rest) | ⬜ | Backend responsibility |
| 2.6.3 | Secure data handling per NDA requirements | ⬜ | |

### 2.7 Logging & Monitoring
| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.7.1 | Comprehensive logging for audit trails | ⬜ | NEW — nothing exists |
| 2.7.2 | Performance monitoring setup | ⬜ | |

### Phase 2 Deliverables
| # | Deliverable | Status |
|---|-------------|--------|
| D2.1 | Fully functional backend services for Part A scope | ⬜ |
| D2.2 | Updated database schemas and migration scripts | ⬜ |
| D2.3 | Comprehensive API documentation | ⬜ |
| D2.4 | API testing suite (unit and integration tests) | ⬜ |

---

# PHASE 3 — Frontend & Application Changes (Weeks 3–6)

**Duration:** 12–14 business days  
**Checkpoint:** Feature demo with product team  
**Tech Stack:** React 19 + TypeScript, Tailwind CSS 4 + MUI 7, Redux Toolkit, Vite 6

### 3.1 Admin Dashboard Enhancements
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.1.1 | Existing admin dashboard with stats & charts | ✅ | Users/Hosts/Properties/Bookings cards + 2 charts + latest tables |
| 3.1.2 | Add revenue/earnings KPI cards to dashboard | ⬜ | NEW — needs FMS backend |
| 3.1.3 | Add property performance overview to dashboard | ⬜ | NEW |
| 3.1.4 | New admin reports page with downloadable reports | ⬜ | NEW — no reports section exists |
| 3.1.5 | Admin search & filter improvements | ✅ | `AdminSearchBar.tsx` exists and works |

### 3.2 Admin Notification System
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.2.1 | Replace placeholder notification sidebar with real notification UI | ⬜ | Currently MUI demo code with fake items |
| 3.2.2 | Notification types (booking alerts, host requests, system alerts) | ⬜ | NEW |
| 3.2.3 | Real-time notification integration (FCM/WebSocket) | ⬜ | NEW |
| 3.2.4 | Notification preferences in admin settings | ⬜ | NEW |

### 3.3 Admin Settings Page
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.3.1 | Build complete settings page (currently `<h1>Settings</h1>` stub) | ⬜ | Route exists at `/admin/settings` |
| 3.3.2 | Site configuration settings | ⬜ | NEW |
| 3.3.3 | Notification preferences | ⬜ | NEW |
| 3.3.4 | Role & permission management | ⬜ | NEW — ties into RBAC |
| 3.3.5 | System preferences | ⬜ | NEW |

### 3.4 Admin Host Management Enhancement
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.4.1 | Existing host list page with search/filter | ✅ | `HostManagementPage.tsx` |
| 3.4.2 | Host detail view modal/page | ⬜ | NEW — can only list, no detail view |
| 3.4.3 | Host KYC verification review workflow | ⬜ | NEW |
| 3.4.4 | Host performance analytics view (admin side) | ⬜ | NEW |
| 3.4.5 | Host payout management (admin side) | ⬜ | NEW |

### 3.5 Web Portal — Guest Enhancements
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.5.1 | Home page with map, featured properties, categories, FAQs | ✅ | Fully built |
| 3.5.2 | Property listing with search & sidebar filters | ✅ | Fully built |
| 3.5.3 | Property detail with gallery, booking, map, reviews | ✅ | Fully built |
| 3.5.4 | Booking flow (checkout → Razorpay → confirmation) | ✅ | Fully built |
| 3.5.5 | User dashboard, bookings, profile, transactions | ✅ | Fully built |
| 3.5.6 | Create "Become a Host" page (link exists, page missing) | ⬜ | BROKEN — `/become-a-host` → 404 |
| 3.5.7 | User review submission flow | 🔄 | Admin side works, user submission unclear |
| 3.5.8 | Real-time price negotiation UI | ⬜ | Listed in contract, not found in code |
| 3.5.9 | Enhanced notification dropdown | 🔄 | `NotificationDropdown.tsx` exists, integration unclear |

### 3.6 Web Portal — Host Portal (Full Build Required)
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.6.1 | Host layout & navigation (HostHeader + HostSidebar exist) | 🔄 | Layout components exist, need content pages |
| 3.6.2 | Host Dashboard — earnings summary, recent bookings, occupancy stats | ⬜ | Currently `<h1>Host Dashboard</h1>` stub |
| 3.6.3 | Host Property Management — list & manage own properties | ⬜ | NEW |
| 3.6.4 | Host Booking Management — view bookings on their properties | ⬜ | NEW |
| 3.6.5 | Host Earnings & Payout History | ⬜ | NEW |
| 3.6.6 | Host Profile & Banking Details | ⬜ | NEW |
| 3.6.7 | Host Performance Metrics / Charts | ⬜ | NEW |
| 3.6.8 | Host Communication Center (messages) | ⬜ | NEW |
| 3.6.9 | Host Support Tickets | ⬜ | NEW |

### 3.7 Design System Alignment
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.7.1 | Consistent colors, typography, spacing per AAJOO standards | 🔄 | MUI theme exists at `src/theme/`, Tailwind configured |
| 3.7.2 | UI component library for consistency | 🔄 | `src/components/Element/` has button, spinner, snackbar. Needs expansion for FMS/HMS |

### 3.8 Responsive Design
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.8.1 | Mobile optimization — existing pages | 🔄 | Tailwind responsive classes used, needs audit |
| 3.8.2 | Mobile optimization — new FMS/HMS pages | ⬜ | NEW |
| 3.8.3 | Tablet optimization | ⬜ | Needs audit |
| 3.8.4 | Desktop optimization | ✅ | Primary development target |

### 3.9 Performance Optimization
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.9.1 | Fast load times | 🔄 | Vite handles bundling, needs audit |
| 3.9.2 | Smooth animations (Framer Motion) | ✅ | `framer-motion` integrated |
| 3.9.3 | Efficient state management (Redux) | ✅ | 45+ slices well-organized |

### 3.10 New Redux State for FMS/HMS
| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.10.1 | Create Redux slices for Finance — Ledger, Payouts, Invoices, Reconciliation, Reports | ✅ | DONE — 17 slices in `src/features/admin/finance/` |
| 3.10.2 | Create Redux slices for Host Portal — HostDashboard, HostBookings, HostEarnings, HostProfile | ⬜ | NEW — `src/features/host/` |
| 3.10.3 | Create Redux slices for Notifications | ⬜ | NEW |
| 3.10.4 | Create Redux slices for Admin Settings | ⬜ | NEW |
| 3.10.5 | Add new FMS/HMS API endpoints to `endpoints.ts` | 🔄 | Currently 41 endpoints + 25 FMS endpoints added; ~5+ HMS endpoints still needed |

### Phase 3 Deliverables
| # | Deliverable | Status |
|---|-------------|--------|
| D3.1 | Enhanced web portal and admin dashboard | ⬜ |
| D3.2 | UI component library for consistency | 🔄 |
| D3.3 | User acceptance testing ready builds | ⬜ |

---

# PHASE 4 — Finance & Host Management System (Weeks 4–7)

**Duration:** 8–10 business days  
**Checkpoint:** Architectural review and design approval with stakeholders  
**Note:** ALL tasks below are NEW — nothing from Phase 4 exists in the codebase.

## 4A. Finance Management System (FMS) — 🔄 In Progress (~97%)

### 4A.1 Ledger Management
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.1.1 | Host ledgers — list, detail view, filters | ✅ | HostLedger page + hostLedger slice connected to real API; mock fallback removed |
| 4A.1.2 | Guest ledgers — list, detail view, filters | ✅ | GuestLedger page + guestLedger slice connected to real API; mock fallback removed |
| 4A.1.3 | Transaction history module — search, filter, export | ✅ | LedgerList connected to real API with search/filter/export and live empty/error states |
| 4A.1.4 | Real-time ledger updates (booking, payment, refund, cancellation events) | ⬜ | WebSocket or polling — needs backend |

### 4A.2 Payout Processing
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.2.1 | Payout calculation engine (frontend display) | ✅ | PayoutQueue uses real API data/actions; mock fallback removed |
| 4A.2.2 | Schedule management UI (daily, weekly, monthly, on-demand) | ✅ | PayoutSchedules CRUD flow connected to real API |
| 4A.2.3 | Payment execution status tracking | ✅ | PayoutHistory connected to real API with status tabs and export |
| 4A.2.4 | Configurable payout schedule settings | ✅ | Payout schedule create/update live via backend endpoints |

### 4A.3 Reconciliation
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.3.1 | Booking-to-payout reconciliation view | ✅ | ReconciliationList connected to real API + resolve flow + summary cards |
| 4A.3.2 | Gateway reconciliation view | ⬜ | |
| 4A.3.3 | Variance reports page | ⬜ | |
| 4A.3.4 | Automated reconciliation status dashboard | ✅ | ReconciliationDashboard connected to real API with live summary metrics |

### 4A.4 Reports & Analytics
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.4.1 | Revenue reports page | ✅ | RevenueReport connected to real API; mock fallback removed |
| 4A.4.2 | Commission tracking page | ✅ | CommissionReport connected to real API; mock fallback removed |
| 4A.4.3 | Tax summaries page | ✅ | TaxSummary connected to real API with INR formatting and GST/TDS-ready types |
| 4A.4.4 | Cash flow reports page | ✅ | CashFlowReport connected to real API; mock fallback removed |
| 4A.4.5 | Finance Dashboard — KPIs: total revenue, commission, net payouts, pending | ✅ | FinanceDashboard now driven by backend payloads |
| 4A.4.6 | Transaction search and filter | ✅ | Fully live with API search/filter/export and server pagination |

### 4A.5 Invoice Generation
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.5.1 | Automated invoice list view | ✅ | InvoiceList connected to real API and backend PDF download endpoint |
| 4A.5.2 | Invoice detail view | ✅ | InvoiceDetail connected to real API; mock fallback removed |
| 4A.5.3 | Invoice download (PDF) | ✅ | Download flow wired to live endpoint with blob streaming |
| 4A.5.4 | Tax-compliant invoice generation (GST ready) | 🔄 | Frontend now includes GST/TDS/HSN/GSTIN data model support; backend rules pending |

### 4A.6 FMS Data Models & API Contracts
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.6.1 | FinancialLedger (host_id, transaction_type, amount, timestamp) | ✅ | types.ts — LedgerEntry, LedgerStatus, TransactionType, EntryType |
| 4A.6.2 | PayoutSchedule (host_id, frequency, rules, last_payout_date) | ✅ | types.ts — PayoutSchedule, PayoutFrequency, PayoutMethod, PayoutStatus |
| 4A.6.3 | Invoice (invoice_number, host_id, amount, tax, date) | ✅ | types.ts — Invoice, InvoiceType, InvoiceStatus |
| 4A.6.4 | ReconciliationRecord (booking_id, payment_status, payout_status, variance) | ✅ | types.ts — ReconciliationRecord, ReconciliationSummary, ReconciliationStatus |

### 4A.7 FMS Integration Points
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4A.7.1 | Connect to booking system (on booking, cancellation, refund events) | ⬜ | Needs backend |
| 4A.7.2 | Connect to payment gateway (transaction confirmation, failed payment) | ⬜ | Needs backend |
| 4A.7.3 | Connect to host profile (KYC status, payout account details) | ⬜ | Needs backend |
| 4A.7.4 | Admin dashboard integration (reporting and manual adjustments) | 🔄 | ManualPayoutModal + FinanceDashboard built. Pending: backend wiring |
| 4A.7.5 | Audit trail for all financial operations | ⬜ | Needs backend |

---

## 4B. Host Management System (HMS) — ❌ Entirely New

### 4B.1 Host Onboarding
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.1.1 | KYC verification workflow UI | ⬜ | |
| 4B.1.2 | Document upload & management UI | ⬜ | |
| 4B.1.3 | Account activation flow | ⬜ | |
| 4B.1.4 | Admin-side KYC review & approval | ⬜ | |

### 4B.2 Profile Management
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.2.1 | Host information management page | ⬜ | |
| 4B.2.2 | Property details management (host side) | ⬜ | |
| 4B.2.3 | Banking details management page | ⬜ | |
| 4B.2.4 | Host preferences page | ⬜ | |

### 4B.3 Performance Metrics
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.3.1 | Occupancy rates tracking charts | ⬜ | |
| 4B.3.2 | Revenue trends charts | ⬜ | |
| 4B.3.3 | Cancellation rates charts | ⬜ | |
| 4B.3.4 | Ratings & reviews analytics | ⬜ | |
| 4B.3.5 | Property performance analytics dashboard | ⬜ | |

### 4B.4 Payout Management (Host Side)
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.4.1 | Payout history page | ⬜ | |
| 4B.4.2 | Payout account details management | ⬜ | |
| 4B.4.3 | Dispute handling UI | ⬜ | |
| 4B.4.4 | Statement downloads | ⬜ | |
| 4B.4.5 | Automated payouts status view | ⬜ | |

### 4B.5 Communication Logs
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.5.1 | Guest messages system | ⬜ | |
| 4B.5.2 | Support tickets system | ⬜ | |
| 4B.5.3 | System notifications | ⬜ | |
| 4B.5.4 | Host communication center UI | ⬜ | |

### 4B.6 Host Portal Pages
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.6.1 | Host Dashboard (replace stub) | ⬜ | Currently `<h1>Host Dashboard</h1>` |
| 4B.6.2 | Host Statements page | ⬜ | |
| 4B.6.3 | Host Performance Charts page | ⬜ | |
| 4B.6.4 | Host Support Ticket page | ⬜ | |

### 4B.7 HMS Data Models & API Contracts
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.7.1 | Host (host_id, name, contact, KYC_status, profile_score) | ⬜ | Basic host model exists, needs expansion |
| 4B.7.2 | HostProfile (host_id, properties, earnings_summary, rating) | ⬜ | |
| 4B.7.3 | HostPerformance (host_id, occupancy_rate, revenue, cancellations, avg_rating, period) | ⬜ | |
| 4B.7.4 | PayoutAccount (host_id, bank_details, upi_id, preferred_method) | ⬜ | |
| 4B.7.5 | CommunicationLog (host_id, message_type, sender, content, timestamp) | ⬜ | |

### 4B.8 HMS Integration Points
| # | Task | Status | Notes |
|---|------|--------|-------|
| 4B.8.1 | Connect to existing host module (profile and listing management) | ⬜ | Basic host slice exists |
| 4B.8.2 | Connect to finance system (payout calculations and history) | ⬜ | |
| 4B.8.3 | Connect to booking system (occupancy and revenue data) | ⬜ | |
| 4B.8.4 | Push notification service (real-time alerts) | ⬜ | |
| 4B.8.5 | Admin dashboard (host verification and support) | ⬜ | |

### Phase 4 Deliverables
| # | Deliverable | Status |
|---|-------------|--------|
| D4.1 | Finance Management System – Detailed Functional Specification | ⬜ |
| D4.2 | Host Management System – Detailed Functional Specification | ⬜ |
| D4.3 | Data model diagrams and ERDs for both systems | ⬜ |
| D4.4 | API contract specifications (endpoints, request/response formats) | ⬜ |
| D4.5 | Integration architecture showing touchpoints with Part A | ⬜ |
| D4.6 | User journey diagrams for finance and host portals | ⬜ |
| D4.7 | Implementation roadmap with effort estimates | ⬜ |
| D4.8 | Risk assessment and mitigation strategies | ⬜ |

---

# PHASE 5 — Quality Assurance, UAT & Deployment (Weeks 8–9)

**Duration:** 6–8 business days  
**Critical Gate:** UAT sign-off from AAJOO before deployment

### 5.1 Testing Activities
| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.1.1 | Unit Testing – Backend services, business logic, data validation | ⬜ | |
| 5.1.2 | Integration Testing – API contracts, database interactions, service integrations | ⬜ | |
| 5.1.3 | Regression Testing – Existing features to ensure no breakage | ⬜ | |
| 5.1.4 | Performance Testing – Load testing, stress testing, response time validation | ⬜ | |
| 5.1.5 | Security Testing – Authentication, authorization, data exposure, OWASP checks | ⬜ | |
| 5.1.6 | Accessibility Testing – WCAG compliance, keyboard navigation, screen reader | ⬜ | |
| 5.1.7 | Device & Browser Testing – iOS, Android, Chrome, Safari, Firefox, Edge | ⬜ | |

### 5.2 UAT Process
| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.2.1 | UAT environment setup with production-like data | ⬜ | |
| 5.2.2 | Comprehensive test cases and scenarios delivery | ⬜ | |
| 5.2.3 | Client UAT – AAJOO team tests features per approved requirements | ⬜ | |
| 5.2.4 | Issue triage (Critical, High, Medium, Low classification) | ⬜ | |
| 5.2.5 | Fix & Retest cycle | ⬜ | |
| 5.2.6 | UAT Sign-off – Formal approval from AAJOO leadership | ⬜ | |

### 5.3 Deployment
| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.3.1 | Final pre-deployment checklist verification | ⬜ | |
| 5.3.2 | Database migration – Apply schema changes to production | ⬜ | |
| 5.3.3 | Backend deployment – Deploy new services and APIs | ⬜ | |
| 5.3.4 | Frontend deployment – Vercel (already configured via `vercel.json`) | ⬜ | `vercel.json` exists |
| 5.3.5 | Configuration – Environment variables, API keys, feature flags | ⬜ | |
| 5.3.6 | Smoke testing – Quick validation of critical flows in production | ⬜ | |
| 5.3.7 | Rollback plan preparation | ⬜ | |
| 5.3.8 | Go-Live announcement | ⬜ | |

### Phase 5 Deliverables
| # | Deliverable | Status |
|---|-------------|--------|
| D5.1 | Test cases document with execution results | ⬜ |
| D5.2 | Bug report and resolution summary | ⬜ |
| D5.3 | UAT sign-off document | ⬜ |
| D5.4 | Deployment guide and runbook | ⬜ |
| D5.5 | Operational handover documentation | ⬜ |
| D5.6 | Performance baseline metrics | ⬜ |

---

# PHASE 6 — Post-Launch Support & Stabilization (Weeks 10+, 30 days)

**Duration:** 30 days from production go-live  
**Scope:** Issues directly related to Part A + FMS + HMS implementation

### 6.1 Priority Levels & Response Times
| Priority | Description | Response | Resolution |
|----------|-------------|----------|------------|
| Critical | Complete system down or core feature broken | 2 hours | 4 hours |
| High | Major feature not working or data loss risk | 4 hours | 8 hours |
| Medium | Non-critical feature broken or performance degradation | 8 hours | 24 hours |
| Low | Minor UI issues, documentation corrections | 24 hours | 3 days |

### 6.2 Support Activities
| # | Task | Status | Notes |
|---|------|--------|-------|
| 6.2.1 | Daily monitoring of production logs and performance metrics | ⬜ | |
| 6.2.2 | Quick issue diagnosis and fix deployment | ⬜ | |
| 6.2.3 | User feedback collection and prioritization | ⬜ | |
| 6.2.4 | Knowledge transfer sessions with AAJOO team | ⬜ | |
| 6.2.5 | Release notes and post-launch documentation | ⬜ | |

### Phase 6 Deliverables
| # | Deliverable | Status |
|---|-------------|--------|
| D6.1 | Daily/weekly status reports | ⬜ |
| D6.2 | Incident and resolution logs | ⬜ |
| D6.3 | Performance monitoring reports | ⬜ |
| D6.4 | Knowledge transfer documentation | ⬜ |
| D6.5 | Operational playbook for AAJOO team | ⬜ |

---

# SUMMARY — Work Breakdown

| Category | Total Tasks | Already Done | Partial | Not Started | % Complete |
|----------|------------|--------------|---------|-------------|-----------|
| Step 0 — Immediate Fixes | 8 | 0 | 0 | 8 | 0% |
| Phase 1 — Discovery | 17 | 0 | 0 | 17 | 0% |
| Phase 2 — Backend/API | 18 | 4 | 2 | 12 | ~22% |
| Phase 3 — Frontend | 32 | 13 | 5 | 14 | ~41% |
| Phase 4A — FMS | 27 | 0 | 0 | 27 | 0% |
| Phase 4B — HMS | 27 | 0 | 0 | 27 | 0% |
| Phase 5 — QA/Deploy | 21 | 0 | 0 | 21 | 0% |
| Phase 6 — Support | 5 | 0 | 0 | 5 | 0% |
| **TOTAL** | **155** | **17** | **7** | **131** | **~11%** |

> **Bottom line:** ~11% of the total work is already done (existing admin CRUD, user booking flow, auth system).  
> The biggest gaps are the **entire FMS** (27 tasks) and **entire HMS** (27 tasks) which are brand new.  
> Start with **Step 0** (fix broken stuff), then **Phase 3** (frontend enhancements) in parallel with **Phase 4** (FMS/HMS).

---

# TECHNICAL SPECIFICATIONS

### Tech Stack (Web — This Repo)
| Layer | Technology |
|-------|-----------|
| Frontend | React 19 + TypeScript |
| Styling | Tailwind CSS 4 + MUI 7 |
| State Management | Redux Toolkit (RTK) with ~45+ slices |
| Build Tool | Vite 6 |
| Routing | React Router DOM 7 |
| Forms | React Hook Form + Zod + Formik + Yup |
| Maps | Leaflet, Mapbox GL, Google Maps |
| Payments | Razorpay (existing) |
| Notifications | Firebase Cloud Messaging (FCM) — not yet integrated |
| Charts | MUI X Charts |
| Animations | Framer Motion |
| HTTP Client | Axios with JWT interceptor |
| Deployment | Vercel (configured) |

### Performance Targets
| Metric | Target |
|--------|--------|
| API Response Time | < 200ms (p95) |
| Page Load Time | Optimized for fast load |
| State Management | Efficient Redux patterns |

### Security Requirements
| Layer | Measures |
|-------|----------|
| Authentication | JWT tokens with expiration, refresh token rotation, MFA-ready |
| Authorization | RBAC with fine-grained permissions (currently only basic admin auth) |
| Data Encryption | HTTPS (TLS 1.2+) for transit, AES-256 for sensitive data at rest |
| API Security | Rate limiting, request validation, SQL injection prevention, XSS protection |
| Database | Prepared statements, parameterized queries, no hardcoded credentials |
| Audit Trail | Logging of critical operations with timestamps and user identity |
| Secrets | Environment variables, secret vaults for API keys and credentials |

---

# OUT OF SCOPE

The following are **NOT** included in this engagement:
- Future major enhancements to FMS & HMS beyond modules defined in this document
- New mobile app features outside the agreed feature list
- Major redesign of existing user interfaces (visual overhaul)
- Large-scale data migration or legacy system rebuilding
- Third-party subscription costs (cloud, SaaS, payment processors)
- Extended maintenance beyond 30 days
- New integrations with external systems not mentioned in the PRD
- Compliance consulting and formal certifications
- Content creation for help centers or marketing

---

# DEPENDENCIES & PRE-REQUISITES

| # | Dependency | Status | Notes |
|---|-----------|--------|-------|
| P1 | Access to current codebase (Git repository) | ✅ | This repo — `nameeshPatiyal100/Aajao-Admin-WebSIite` |
| P2 | Development environment setup (local) | ✅ | Vite dev server running at `localhost:5173`, 0 TS errors |
| P3 | Development environment setup (staging, production) | 🔴 | Need from client |
| P4 | Database access (production-equivalent staging DB) | 🔴 | Need from client |
| P5 | Third-party service credentials (Razorpay, Firebase, etc.) | 🔴 | Need from client |
| P6 | Design files and UI specifications (Figma, XD, or similar) | 🔴 | Need from client |
| P7 | Stakeholder contact list | 🔴 | Need from client |
| P8 | Testing environment readiness | ⬜ | |
| P9 | Backend API server access | 🔴 | API points to `localhost:8000`, need backend repo/server |

---

*Last Updated: March 10, 2026*
