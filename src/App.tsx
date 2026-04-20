import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import "./App.css";
import notFound from "./assets/UI/404.jpg";
import { AdminLayout } from "./components";
import AdminProtectedRoute from "./components/authGaurd";
import { SidebarProvider } from "./context/AdminContext";
import AdminBooking from "./pages/admin/adminBooking/AdminBooking";
import {
  AdminLogin,
  Dashboard,
  StatusPage,
  UserManagementPage,
  AboutUs,
  ContactUs,
  PropertyDetail,
  NotFound,
  FAQ,
  DashboardLayout,
  PropertyListing,
  FinalBookingPage,
  BookingConfirmed,
  CancelBookResult,
  UserCheckoutPage,
  StateRegulation,
  HelpCenter,
  TermsAndConditions,
  HostManagementPage,
  WhyHostsListWithAajoo,
  PrivacyPolicyPage,
  PropertyCategory,
  PropertyAmenity,
  PropertyTag,
  Properties,
  PropertiesForm,
  PropertiesVerifications,
  PropertyReviews,
} from "./pages";

// Finance Management System pages
import FinanceDashboard from "./pages/admin/finance/FinanceDashboard";
import LedgerList from "./pages/admin/finance/LedgerList";
import HostLedger from "./pages/admin/finance/HostLedger";
import GuestLedger from "./pages/admin/finance/GuestLedger";
import PayoutQueue from "./pages/admin/finance/PayoutQueue";
import PayoutSchedules from "./pages/admin/finance/PayoutSchedules";
import PayoutHistory from "./pages/admin/finance/PayoutHistory";
import ReconciliationDashboard from "./pages/admin/finance/ReconciliationDashboard";
import ReconciliationList from "./pages/admin/finance/ReconciliationList";
import InvoiceList from "./pages/admin/finance/InvoiceList";
import InvoiceDetail from "./pages/admin/finance/InvoiceDetail";
import RevenueReport from "./pages/admin/finance/RevenueReport";
import CommissionReport from "./pages/admin/finance/CommissionReport";
import TaxSummary from "./pages/admin/finance/TaxSummary";
import CashFlowReport from "./pages/admin/finance/CashFlowReport";

// NEED TO SET ORDER
import CommonLayout from "./components/layout/CommonLayout";
import { Home } from "./pages";
import GuestRoute from "./components/authGaurd";
import { LoginForm } from "./auth/Forms/LoginForm";
import UserSignup from "./auth/UserSignup";
import SignupOtpVerification from "./auth/SignupOtpVerification";
import { ForgotPassword } from "./auth/ForgotPassword";
import { VerifyOtp } from "./auth/VerifyOtp";
import { ResetPassword } from "./auth/ResetPassword";

function App() {
  return (
    <Router>
      {/* <Toaster position="top-left" reverseOrder={false} /> */}
      <Routes>
        <Route path="/" element={<CommonLayout />}>
          <Route index element={<Home />} />
          <Route path="about" element={<AboutUs />} />
          <Route path="contact" element={<ContactUs />} />
          <Route path="property/detail/:id" element={<PropertyDetail />} />
          <Route path="property/list" element={<PropertyListing />} />
          <Route path="faqs" element={<FAQ />} />
          <Route path="/user-dashboard" element={<DashboardLayout />} />
          <Route
            path="/property-booking/final"
            element={<FinalBookingPage />}
          />
          <Route path="/booking/confirmation" element={<BookingConfirmed />} />
          <Route
            path="/booking/cancel-result/:bookingId"
            element={<CancelBookResult />}
          />
          <Route path="/user/checkout/:id" element={<UserCheckoutPage />} />
          <Route path="/state-regulation" element={<StateRegulation />} />
          {/* <Route path="/state-regulation" element={<StateRegulation />} /> */}
          <Route path="/help-center" element={<HelpCenter />} />
          <Route path="/terms-condition" element={<TermsAndConditions />} />
          <Route
            path="/Why-Hosts-List-With-Aajoo"
            element={<WhyHostsListWithAajoo />}
          />
          <Route path="/Privacy-Policy" element={<PrivacyPolicyPage />} />
          <Route path="*" element={<NotFound image={notFound} />} />
        </Route>

        {/* Auth Routes */}
        <Route path="/auth" element={<GuestRoute />}>
          <Route element={<CommonLayout />}>
            <Route path="login" element={<LoginForm />} />
            <Route path="forget" element={<ForgotPassword />} />
            <Route path="signup" element={<UserSignup />} />
            <Route path="verifyOtp" element={<VerifyOtp />} />
            <Route
              path="signup-verication"
              element={<SignupOtpVerification />}
            />
            <Route path="reset-password" element={<ResetPassword />} />
          </Route>
        </Route>
        <Route path="/admin/login" element={<AdminLogin />} />

        <Route element={<AdminProtectedRoute />}>
          <Route
            path="/admin/*"
            element={
              <SidebarProvider>
                <AdminLayout />
              </SidebarProvider>
            }
          >
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="users" element={<UserManagementPage />} />
            {/* <Route path="transactions" element={<Transactions />} /> */}
            <Route path="host" element={<HostManagementPage />} />
            <Route path="properties" element={<Properties />} />
            <Route
              path="property-verification"
              element={<PropertiesVerifications />}
            />
            <Route path="properties/form" element={<PropertiesForm />} />
            <Route path="properties/form/:id" element={<PropertiesForm />} />
            <Route path="tags" element={<PropertyTag />} />
            <Route path="categories" element={<PropertyCategory />} />
            <Route path="amenities" element={<PropertyAmenity />} />
            <Route path="property-reviews" element={<PropertyReviews />} />
            <Route path="bookings" element={<AdminBooking />} />
            <Route path="status" element={<StatusPage />} />

            {/* Finance Management System */}
            <Route path="finance" element={<FinanceDashboard />} />
            <Route path="finance/ledgers" element={<LedgerList />} />
            <Route path="finance/ledgers/host/:hostId" element={<HostLedger />} />
            <Route path="finance/ledgers/guest/:userId" element={<GuestLedger />} />
            <Route path="finance/payouts" element={<PayoutQueue />} />
            <Route path="finance/payouts/schedules" element={<PayoutSchedules />} />
            <Route path="finance/payouts/history" element={<PayoutHistory />} />
            <Route path="finance/reconciliation" element={<ReconciliationDashboard />} />
            <Route path="finance/reconciliation/records" element={<ReconciliationList />} />
            <Route path="finance/invoices" element={<InvoiceList />} />
            <Route path="finance/invoices/:invoiceId" element={<InvoiceDetail />} />
            <Route path="finance/reports/revenue" element={<RevenueReport />} />
            <Route path="finance/reports/commission" element={<CommissionReport />} />
            <Route path="finance/reports/tax" element={<TaxSummary />} />
            <Route path="finance/reports/cashflow" element={<CashFlowReport />} />

            <Route path="settings" element={<h1>Settings</h1>} />
            <Route path="*" element={<Navigate to="/admin/dashboard" />} />
          </Route>
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
