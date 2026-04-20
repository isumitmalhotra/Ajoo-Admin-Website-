import { configureStore } from "@reduxjs/toolkit";
import uiReducer from "../features/ui/ui.slice";
import adminAuthReducer from "../features/admin/adminAuth/adminAuth.slice";
import propertyCategoryReducer from "../features/admin/propertyCategory/propertyCategory.slice";
import propertyCategoryDetailsReducer from "../features/admin/propertyCategory/propertyCategoryDetails.slice";
import propertyCategoryAddUpdateReducer from "../features/admin/propertyCategory/propertyCategoryAddUpdate.slice";
import propertyCategoryStatusReducer from "../features/admin/propertyCategory/propertyCategoryStatus.slice";
import propertyCategoryDeleteReducer from "../features/admin/propertyCategory/propertyCategoryDelete.slice";
import propertyTagReducer from "../features/admin/propertyTag/propertyTag.slice";
import propertyTagDetailsReducer from "../features/admin/propertyTag/propertyTagDetails.slice";
import propertyTagAddUpdateReducer from "../features/admin/propertyTag/propertyTagAddUpdate.slice";
import propertyTagStatusReducer from "../features/admin/propertyTag/propertyTagStatus.slice";
import propertyTagDeleteReducer from "../features/admin/propertyTag/propertyTagDelete.slice";
import propertyAmenityReducer from "../features/admin/propertyAmenity/propertyAmenity.slice";
import propertyAmenityDetailsReducer from "../features/admin/propertyAmenity/propertyAmenityDetails.slice";
import propertyAmenityAddUpdateReducer from "../features/admin/propertyAmenity/propertyAmenityAddUpdate.slice";
import propertyAmenityStatusReducer from "../features/admin/propertyAmenity/propertyAmenityStatus.slice";
import propertyAmenityDeleteReducer from "../features/admin/propertyAmenity/propertyAmenityDelete.slice";
import propertyReducer from "../features/admin/properties/property.slice";
import propertyDetailsReducer from "../features/admin/properties/propertyDetails.slice";
import propertyAddUpdateReducer from "../features/admin/properties/propertyAddUpdate.slice";
import propertyStatusReducer from "../features/admin/properties/propertyStatus.slice";
import propertyDeleteReducer from "../features/admin/properties/propertyDelete.slice";
import userReducer from "../features/admin/userManagement/user.slice";
import userDetailsReducer from "../features/admin/userManagement/userDetails.slice";
import userDeleteReducer from "../features/admin/userManagement/userDelete.slice";
import userAddUpdateReducer from "../features/admin/userManagement/userAddUpdate.slice";
import userImageDeleteReducer from "../features/admin/userManagement/UserImageDelete.slice";
import hostReducer from "../features/admin/userManagement/host.slice";
import userStatusUpdateReducer from "../features/admin/userManagement/userStatusUpdate.slice";
import hostForPropertyReducer from "../features/admin/userManagement/hostForProperty.slice";
import tagsDropdownReducer from "../features/admin/propertyTag/tagsDropdown.slice";
import amenitiesDropdownReducer from "../features/admin/propertyAmenity/amenitiesDropdown.slice";
import categoryDropdownReducer from "../features/admin/propertyCategory/categoryDropdown.slice";
import propertyByIdReducer from "../features/admin/properties/propertyById.slice";
import bookingListReducer from "../features/admin/Bookings/fetchBooking.slice";
import bookingDetailReducer from "../features/admin/Bookings/bookingDetail.slice";
import bookingStatusReducer from "../features/admin/Bookings/bookingStatus.slice";
import updateBookingStatusReducer from "../features/admin/Bookings/updateBookingStatus.slice";
import deletePropertyImageReducer from "../features/admin/properties/deletePropertyImage.slice";
import bookingStatusListingForAdminPageReducer from "../features/admin/BookingStatus/bookingStatusListingForAdminPage.slice";
import updateBookingStatusAdminPageReducer from "../features/admin/BookingStatus/bookingStatusUpdateSlice";
import adminDashboardSliceReducer from "../features/admin/Dashboard/dashboard.slice";

// ================= FINANCE MANAGEMENT SYSTEM =================
import financeDashboardReducer from "../features/admin/finance/financeDashboard.slice";
import ledgerListReducer from "../features/admin/finance/ledgerList.slice";
import ledgerDetailReducer from "../features/admin/finance/ledgerDetail.slice";
import hostLedgerReducer from "../features/admin/finance/hostLedger.slice";
import guestLedgerReducer from "../features/admin/finance/guestLedger.slice";
import payoutListReducer from "../features/admin/finance/payoutList.slice";
import payoutDetailReducer from "../features/admin/finance/payoutDetail.slice";
import payoutActionReducer from "../features/admin/finance/payoutAction.slice";
import payoutScheduleListReducer from "../features/admin/finance/payoutScheduleList.slice";
import invoiceListReducer from "../features/admin/finance/invoiceList.slice";
import invoiceDetailReducer from "../features/admin/finance/invoiceDetail.slice";
import reconciliationListReducer from "../features/admin/finance/reconciliationList.slice";
import reconciliationResolveReducer from "../features/admin/finance/reconciliationResolve.slice";
import revenueReportReducer from "../features/admin/finance/revenueReport.slice";
import commissionReportReducer from "../features/admin/finance/commissionReport.slice";
import taxReportReducer from "../features/admin/finance/taxReport.slice";
import cashFlowReportReducer from "../features/admin/finance/cashFlowReport.slice";

export const store = configureStore({
  reducer: {
    ui: uiReducer,
    // ADMINREDUCERS
    adminAuth: adminAuthReducer,
    users: userReducer,
    hosts: hostReducer,
    userDetails: userDetailsReducer,
    userAddUpdate: userAddUpdateReducer,
    userImageDelete: userImageDeleteReducer,
    userDelete: userDeleteReducer,
    hostForProperty: hostForPropertyReducer,
    userStatusUpdate: userStatusUpdateReducer,
    propertyCategory: propertyCategoryReducer,
    propertyCategoryDetails: propertyCategoryDetailsReducer,
    propertyCategoryAddUpdate: propertyCategoryAddUpdateReducer,
    propertyCategoryStatus: propertyCategoryStatusReducer,
    propertyCategoryDelete: propertyCategoryDeleteReducer,
    propertyTag: propertyTagReducer,
    tagsDropdown: tagsDropdownReducer,
    amenitiesDropdown: amenitiesDropdownReducer,
    categoryDropdown: categoryDropdownReducer,
    propertyById: propertyByIdReducer,
    propertyTagDetails: propertyTagDetailsReducer,
    propertyTagAddUpdate: propertyTagAddUpdateReducer,
    propertyTagStatus: propertyTagStatusReducer,
    propertyTagDelete: propertyTagDeleteReducer,
    propertyAmenity: propertyAmenityReducer,
    propertyAmenityDetails: propertyAmenityDetailsReducer,
    propertyAmenityAddUpdate: propertyAmenityAddUpdateReducer,
    propertyAmenityStatus: propertyAmenityStatusReducer,
    propertyAmenityDelete: propertyAmenityDeleteReducer,
    properties: propertyReducer,
    propertyDetails: propertyDetailsReducer,
    propertyAddUpdate: propertyAddUpdateReducer,
    propertyStatus: propertyStatusReducer,
    propertyDelete: propertyDeleteReducer,
    bookingList: bookingListReducer,
    bookingDetail: bookingDetailReducer,
    bookingStatus: bookingStatusReducer,
    updateBookingStatus: updateBookingStatusReducer,
    deletePropertyImage: deletePropertyImageReducer,
    bookingStatusListingForAdminPage: bookingStatusListingForAdminPageReducer,
    updateBookingStatusAdminPage: updateBookingStatusAdminPageReducer,
    adminDashboardSlice: adminDashboardSliceReducer,

    // ================= FINANCE MANAGEMENT SYSTEM =================
    financeDashboard: financeDashboardReducer,
    ledgerList: ledgerListReducer,
    ledgerDetail: ledgerDetailReducer,
    hostLedger: hostLedgerReducer,
    guestLedger: guestLedgerReducer,
    payoutList: payoutListReducer,
    payoutDetail: payoutDetailReducer,
    payoutAction: payoutActionReducer,
    payoutScheduleList: payoutScheduleListReducer,
    invoiceList: invoiceListReducer,
    invoiceDetail: invoiceDetailReducer,
    reconciliationList: reconciliationListReducer,
    reconciliationResolve: reconciliationResolveReducer,
    revenueReport: revenueReportReducer,
    commissionReport: commissionReportReducer,
    taxReport: taxReportReducer,
    cashFlowReport: cashFlowReportReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
