# Host Management System (HMS) Sprint Plan

## Scope Decision
- Primary focus: Host Management first (admin + host portal foundations).
- Deferred: Finance backend dependency fixes and non-host modules.
- Delivery model: 5 implementation sprints + 1 stabilization sprint.

## Assumptions
- Frontend repository only; backend APIs may be partial.
- Existing admin host list page is available and working.
- Host portal is currently a stub and needs full implementation.

## Definition of Done
- Feature implemented with loading/empty/error states.
- Build passes (`npm run build`).
- Route reachable and manually verified on local.
- Integrated into store and navigation where required.
- No merge markers, no TypeScript errors.

## Sprint 0 (Today) - Planning + First Delivery

### HMS-0001 - Create HMS execution plan
- Type: Documentation
- Estimate: 2h
- Dependencies: None
- Deliverables:
  - This plan document with ticketing, sequence, and dependencies.

### HMS-0002 - Admin Host Detail View (first shipped host task)
- Type: Frontend implementation
- Estimate: 4h
- Dependencies: Existing host list page
- Goal:
  - Add a host detail dialog from host-management table actions.
- File-level sequence:
  1. Add dialog component: src/pages/admin/host-management/HostDetailDialog.tsx
  2. Update actions: src/pages/admin/host-management/HostActions.tsx
  3. Update host page state/handlers: src/pages/admin/host-management/HostManagementPage.tsx
- Acceptance:
  - "View" action visible in each host row.
  - Click opens dialog with host summary data.
  - Dialog close works and does not affect edit/delete behavior.

## Sprint 1 - Admin Host Management Enhancements (Core)

### HMS-1001 - Host detail data enrichment
- Estimate: 6h
- Dependencies: HMS-0002
- API dependencies:
  - Optional new endpoint: /admin/host/detail (or reuse /admin/user/single for host users)
- Tasks:
  - Extend dialog to show verification, joined date, property count, contact, status timeline.
  - Add skeleton loading + error state.

### HMS-1002 - KYC Review Workflow (admin side)
- Estimate: 12h
- Dependencies: HMS-1001
- API dependencies:
  - /admin/host/kyc/detail
  - /admin/host/kyc/approve
  - /admin/host/kyc/reject
- Tasks:
  - KYC status chips and document preview section.
  - Approve/Reject modal with reason.
  - Update list state after action.

### HMS-1003 - Host performance snapshot (admin side)
- Estimate: 10h
- Dependencies: HMS-1001
- API dependencies:
  - /admin/host/performance/summary
- Tasks:
  - KPI cards: occupancy, earnings, cancellations, rating.
  - Last 30/90 days filter.

### HMS-1004 - Admin host payout pane
- Estimate: 10h
- Dependencies: HMS-1001
- API dependencies:
  - /admin/host/payout/history
  - /admin/host/payout/hold
  - /admin/host/payout/release
- Tasks:
  - Recent payouts table + status.
  - Hold/release controls with confirmation.

## Sprint 2 - Host Portal Foundation

### HMS-2001 - Host portal route architecture
- Estimate: 6h
- Dependencies: None
- Tasks:
  - Add /host/* route tree in App.
  - Add Host layout with sidebar/header and Outlet.
  - Add route guards placeholder for host role.
- File-level sequence:
  1. src/App.tsx
  2. src/pages/host/layout/HostLayout.tsx
  3. src/components/layout/HostSidebar.tsx (wire links)
  4. src/components/layout/HostHeader.tsx (role-safe display)

### HMS-2002 - Replace host dashboard stub
- Estimate: 8h
- Dependencies: HMS-2001
- API dependencies:
  - /host/dashboard/summary (or admin-host proxy)
- Tasks:
  - KPI cards, recent bookings, earnings trend placeholder chart.
  - loading/empty/error states with mock fallback in DEV only.
- File-level sequence:
  1. src/pages/host/dashboard.tsx
  2. src/pages/host/mockData.ts (temporary)

### HMS-2003 - Host redux slices foundation
- Estimate: 8h
- Dependencies: HMS-2001
- Tasks:
  - Add src/features/host/ directory.
  - Create slices: hostDashboard, hostBookings, hostEarnings, hostProfile.
  - Register reducers in store.
- File-level sequence:
  1. src/features/host/*.slice.ts
  2. src/app/store.ts

## Sprint 3 - Host Operational Pages

### HMS-3001 - Host bookings page
- Estimate: 10h
- Dependencies: HMS-2003
- API dependencies:
  - /host/bookings/search
  - /host/bookings/detail

### HMS-3002 - Host earnings and payout history page
- Estimate: 12h
- Dependencies: HMS-2003
- API dependencies:
  - /host/earnings/summary
  - /host/payout/history

### HMS-3003 - Host profile and banking details page
- Estimate: 12h
- Dependencies: HMS-2003
- API dependencies:
  - /host/profile/get
  - /host/profile/update
  - /host/payout-account/get
  - /host/payout-account/update

### HMS-3004 - Host statements download page
- Estimate: 8h
- Dependencies: HMS-3002
- API dependencies:
  - /host/statements/search
  - /host/statements/download/:id

## Sprint 4 - Host Analytics + Communication

### HMS-4001 - Host performance charts page
- Estimate: 10h
- Dependencies: HMS-3001, HMS-3002
- API dependencies:
  - /host/performance/occupancy
  - /host/performance/revenue
  - /host/performance/cancellations
  - /host/performance/ratings

### HMS-4002 - Host support tickets page
- Estimate: 10h
- Dependencies: HMS-2001
- API dependencies:
  - /host/support/tickets/search
  - /host/support/tickets/create
  - /host/support/tickets/reply

### HMS-4003 - Host communication center
- Estimate: 12h
- Dependencies: HMS-4002
- API dependencies:
  - /host/messages/list
  - /host/messages/send
  - Optional websocket channel

## Sprint 5 - Integration + Hardening

### HMS-5001 - HMS endpoint contracts in endpoints.ts
- Estimate: 4h
- Dependencies: Sprint 2-4 API agreement
- File:
  - src/services/endpoints.ts

### HMS-5002 - Validation schemas for HMS forms
- Estimate: 6h
- Dependencies: HMS-3003, HMS-4002
- File:
  - src/validations/admin-validations.tsx (or split host-validations.ts)

### HMS-5003 - Role guard and permissions
- Estimate: 8h
- Dependencies: HMS-2001
- Tasks:
  - Ensure host routes are isolated from admin routes.
  - Restrict action controls by role.

### HMS-5004 - QA checklist and regression pass
- Estimate: 8h
- Dependencies: all prior tickets
- Tasks:
  - Manual checks for host list, detail, status updates, host portal pages.
  - Build, route, and edge-case validation.

## API Dependency Pack to Request from Backend Team
- Host admin APIs: detail, kyc detail/approve/reject, performance summary, payout actions.
- Host portal APIs: dashboard, bookings, earnings, profile, payout account, statements, support, messages.
- Auth/role claims: explicit host role claim for route guards.

## Recommended Execution Order (Exact)
1. HMS-0002 (ship now)
2. HMS-1001 -> HMS-1002
3. HMS-2001 -> HMS-2002 -> HMS-2003
4. HMS-3001 -> HMS-3002 -> HMS-3003 -> HMS-3004
5. HMS-4001 -> HMS-4002 -> HMS-4003
6. HMS-5001 -> HMS-5002 -> HMS-5003 -> HMS-5004

## Risk Register
- Backend endpoint readiness lag (highest risk).
- Missing host role claim in auth payload.
- Data-model mismatch between admin-host and host-portal views.
- Existing style inconsistency between legacy host components and admin MUI patterns.

## Immediate Next 3 Tickets
1. HMS-0002 - Admin Host Detail View (in progress now)
2. HMS-1001 - Host detail data enrichment
3. HMS-2001 - Host portal route architecture
