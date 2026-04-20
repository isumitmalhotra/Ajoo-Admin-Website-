export const ADMINENDPOINTS = {
  // ADMIN
  ADMIN_LOGIN: "/admin/login",
  GET_ADMIN_DASHBOARD_DATA: "/admin/dashboard",
  // USER
  USER_LIST: "/admin/user/search",
  USER_BY_ID: "/admin/user/single",
  USER_ADD_UPDATE: "/admin/user/create",
  USER_IMAGE_DELETE: "/admin/user/delete/image",
  DELETE_USER: "/admin/user/delete",
  HOST_LIST: "/admin/host/search",
  HOST_STATUS_UPDATE: "/admin/user/update/status",
  HOST_SEARCH_ASSIGN_PROPERTY: "/admin/host/search/assign-property",
  HOST_KYC_APPROVE: "/admin/host/kyc/approve",
  HOST_KYC_REJECT: "/admin/host/kyc/reject",
  
  // PROPERTY-CATEGORY
  PROPERTY_CATEGORIES: "admin/categories",
  PROPERTY_CATEGORY_BY_ID: "admin/category",
  PROPERTY_CATEGORY_ADD_UPDATE: "/admin/category/create",
  PROPERTY_CATEGORY_STATUS: "/admin/category/update-status",
  PROPERTY_CATEGORY_DELETE: "/admin/categories/delete",
  CATEGORY_DROPDOWN: "/admin/category/list/dropdowns",
  PROPERTY_TAGS: "admin/tag/search",
  PROPERTY_TAG_BY_ID: "admin/tag/single",
  PROPERTY_TAG_ADD_UPDATE: "/admin/tag/create",
  PROPERTY_TAG_STATUS: "/admin/tag/update-status",
  PROPERTY_TAG_DELETE: "/admin/tag/delete",
  PROPERTY_TAG_DROPDOWN: "/admin/tag/listing/dropdowns",
  PROPERTY_AMENITIES: "admin/amenity/search",
  PROPERTY_AMENITY_BY_ID: "admin/amenity",
  PROPERTY_AMENITY_ADD_UPDATE: "/admin/amenity/create",
  PROPERTY_AMENITY_STATUS: "/admin/amenity/update-status",
  PROPERTY_AMENITY_DELETE: "/admin/amenity/delete",
  AMENITIES_DROPDOWN: "/admin/amenity/list/dropdowns",
  PROPERTIES_LIST: "admin/properties/search",
  PROPERTY_BY_ID: "/admin/property",
  PROPERTY_ADD_UPDATE: "/admin/property/create",
  PROPERTY_STATUS: "/admin/properties/update-status",
  PROPERTY_DELETE: "/admin/property/delete",
  DELETE_PROPERTY_IMAGE: "/admin/properties/delete/image",

  //BOOKINGS
  BOOKING_LIST: "/admin/booking/search",
  BOOKING_DETAIL: "/admin/booking/detail",
  BOOKING_STATUS_LIST:"/admin/booking/status/list",
  UPDATE_BOOKING_STATUS:"/admin/booking/update",
  
  //STATUS LISTING
  BOOKING_STATUS_LIST_FOR_ADMIN:"/admin/booking/status/listing/admin-page",
  UPDATE_BOOKING_STATUS_FROM_STATUS_LISTING_FOR_ADMIN_PAGE:"/admin/booking/status/update",

  // ================= FINANCE MANAGEMENT SYSTEM =================
  // LEDGER
  FINANCE_LEDGER_SEARCH: "/admin/finance/ledger/search",
  FINANCE_LEDGER_BY_ID: "/admin/finance/ledger",
  FINANCE_LEDGER_HOST: "/admin/finance/ledger/host",
  FINANCE_LEDGER_USER: "/admin/finance/ledger/user",
  FINANCE_LEDGER_EXPORT: "/admin/finance/ledger/export",

  // PAYOUT
  FINANCE_PAYOUT_SEARCH: "/admin/finance/payout/search",
  FINANCE_PAYOUT_BY_ID: "/admin/finance/payout",
  FINANCE_PAYOUT_INITIATE: "/admin/finance/payout/initiate",
  FINANCE_PAYOUT_APPROVE: "/admin/finance/payout/approve",
  FINANCE_PAYOUT_REJECT: "/admin/finance/payout/reject",

  // PAYOUT SCHEDULE
  FINANCE_PAYOUT_SCHEDULE_SEARCH: "/admin/finance/payout/schedule/search",
  FINANCE_PAYOUT_SCHEDULE_CREATE: "/admin/finance/payout/schedule/create",
  FINANCE_PAYOUT_SCHEDULE_UPDATE: "/admin/finance/payout/schedule/update",

  // INVOICE
  FINANCE_INVOICE_SEARCH: "/admin/finance/invoice/search",
  FINANCE_INVOICE_BY_ID: "/admin/finance/invoice",
  FINANCE_INVOICE_DOWNLOAD: "/admin/finance/invoice/download",
  FINANCE_INVOICE_VOID: "/admin/finance/invoice/void",

  // RECONCILIATION
  FINANCE_RECONCILIATION_SEARCH: "/admin/finance/reconciliation/search",
  FINANCE_RECONCILIATION_BY_ID: "/admin/finance/reconciliation",
  FINANCE_RECONCILIATION_RESOLVE: "/admin/finance/reconciliation/resolve",
  FINANCE_RECONCILIATION_RUN: "/admin/finance/reconciliation/run",

  // DASHBOARD & REPORTS
  FINANCE_DASHBOARD: "/admin/finance/dashboard",
  FINANCE_REPORT_REVENUE: "/admin/finance/reports/revenue",
  FINANCE_REPORT_COMMISSION: "/admin/finance/reports/commission",
  FINANCE_REPORT_TAX: "/admin/finance/reports/tax",
  FINANCE_REPORT_CASHFLOW: "/admin/finance/reports/cashflow",
  FINANCE_REPORT_EXPORT: "/admin/finance/reports/export",

  // ================= HOST PORTAL (HMS FOUNDATION) =================
  HOST_PORTAL_DASHBOARD: "/host/dashboard/summary",
  HOST_PORTAL_BOOKINGS: "/host/bookings/search",
  HOST_PORTAL_BOOKINGS_EXPORT: "/host/bookings/export",
  HOST_PORTAL_EARNINGS: "/host/earnings/summary",
  HOST_PORTAL_PROFILE: "/host/profile",
  HOST_PORTAL_PROFILE_UPDATE: "/host/profile/update",
};
