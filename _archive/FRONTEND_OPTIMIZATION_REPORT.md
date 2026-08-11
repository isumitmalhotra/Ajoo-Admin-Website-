# Optimization Report

Date: 2026-04-14
Project: `Aajao-Admin-WebSIite`

## Summary

This report captures the optimization and stability work completed so far across the admin app, shared API layer, auth/session handling, notifications, and selected admin modules.

## Completed Work

### 1. Shared API and Session Handling

- Unified the main API usage around the shared axios instance in `src/services/api.ts`.
- Simplified `src/axios/axios.ts` to reuse the shared API instance.
- Added centralized API error normalization in `src/utils/apiError.ts`.
- Added centralized API logging in `src/utils/logger.ts`.
- Updated API config to use env-driven base URL via `src/configs/apiConfigs.ts`.
- Added `.env` with `VITE_API_URL`.
- Standardized storage helpers in `src/styles/utils/storage.ts`.
- Added/used dedicated admin session helpers:
  - `getAdminToken`
  - `setAdminToken`
  - `getAdminUser`
  - `setAdminUser`
  - `clearAdminSession`
- Global `401` handling now clears admin session and redirects properly.

### 2. Admin Auth and Route Stability

- Fixed admin login token persistence.
- Updated admin auth logic to support token extraction from both:
  - `data.token`
  - `data.admin.token`
- Prevented false authenticated state when backend token is missing.
- Updated admin auth slice initialization from stored admin session.
- Removed the brittle admin `verify-token` route gate behavior.
- Simplified protected route handling to rely on stored admin token presence.
- Added a separate guest route instead of reusing the admin guard for `/auth/*`.
- Added a separate button in Menu To Acess Admin Console

### 3. Notification and Snackbar Optimization

- Consolidated snackbar behavior onto shared `src/components/AppSnackbar.tsx`.
- Updated admin/frontend snackbar wrappers to reuse the shared snackbar.
- Routed shared/global notifications through the common notification path.
- Fixed snackbar background styling issue where only blur/white text was visible.
- Shared snackbar now correctly shows severity-based background colors for:
  - success
  - error
  - warning
  - info

### 4. Priority Admin CRUD Optimization

Improved the following modules with cleaner error handling, better loading behavior, and more consistent request flow:

- Property Categories
- Property Tags
- Property Amenities
- Coupons
- FAQ
- Terms and Conditions
- Admin Login

Work included:

- Cleaner `rejectWithValue` handling
- Better use of normalized API error messages
- Loading/submit protection
- Cleaner shared snackbar usage
- Better resilience for changed backend response formats

### 5. Property Analytics Fixes

- Fixed `fetchPropertyAnalytics` handling in `src/features/admin/propertyAnalytics/propertyAnalytics.slice.ts`.
- Updated the analytics list flow to support multiple backend payload shapes.
- Added support for wrapped payload collections such as:
  - `properties`
  - `rows`
  - `records`
  - `items`
  - `list`
  - `analytics`
  - `data`
- Added pagination mapping support for:
  - `totalRecords`
  - `totalCount`
  - `currentPage`
  - `totalPages`
- Treated `404` on property analytics search as an empty state instead of a hard failure.
- Fixed the analytics page so it uses API `totalRecords` instead of only current page item count.
- Improved empty-state messaging on the property analytics list.
- Updated property analytics detail error handling to use shared API error parsing.

### 6. User Edit Modal Fix

- Fixed the user edit modal document number issue.
- The backend response already returned the value under `data.userKycDocs.ud_number`.
- The UI issue was caused by the form clearing `documentNumber` during Formik reinitialization.
- Updated `src/components/admin/modals/userModals/AccountStatus.tsx` so:
  - existing document number is preserved when edit data loads
  - document number is only cleared on a real document type change
  - Aadhaar numeric restriction works consistently

### 7. Admin Navbar Logout

- Updated `src/components/admin/adminnavbar/AdminNavbar.tsx`.
- Logout now:
  - dispatches admin `logout()`
  - clears admin token from local storage
  - clears admin user details from local storage
  - navigates to `/`

### 8. Property Form Success Redirect

- Updated `src/pages/admin/properties/form.tsx`.
- After successful add/update of a property:
  - success message is shown through the shared app snackbar
  - user is redirected back to `/admin/properties`

## Backend Compatibility Adjustments Covered

The frontend work above has already improved compatibility with the newer backend behavior, especially for:

- `401 Unauthorized` handling on admin APIs
- `404 Not Found` empty-result handling on analytics/listing scenarios
- shared error parsing for backend message extraction
- reduced dependence on `success: false` with `200`

