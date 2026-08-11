export interface HostRecentActivity {
  id: string;
  title: string;
  when: string;
  status: string;
}

export interface HostDashboardSummary {
  monthEarnings?: number;
  activeListings?: number;
  upcomingBookings?: number;
  occupancyRate?: number;
  recentActivity?: HostRecentActivity[];
}

export interface HostBooking {
  booking_id: number;
  property_name?: string;
  guest_name?: string;
  check_in?: string;
  check_out?: string;
  amount?: number;
  status?: string;
  created_at?: string;
}

export interface HostBookingsFilters {
  search: string;
  status: string;
  dateFrom: string;
  dateTo: string;
}

export interface HostBookingsListResponse {
  rows: HostBooking[];
  totalPages: number;
  currentPage: number;
  totalRecords: number;
}

export interface HostPayoutRow {
  payout_id?: number;
  booking_id?: number;
  amount?: number;
  status?: string;
  payout_date?: string;
  reference_id?: string;
}

export interface HostEarningsData {
  totalEarnings?: number;
  pendingPayouts?: number;
  settledPayouts?: number;
  lastPayoutAmount?: number;
  nextPayoutDate?: string;
  payoutHistory?: HostPayoutRow[];
}

export interface HostProfileData {
  fullName?: string;
  email?: string;
  phone?: string;
  city?: string;
  bankName?: string;
  accountNumber?: string;
  upiId?: string;
  ifscCode?: string;
}

export interface HostProfilePayload {
  fullName: string;
  email: string;
  phone: string;
  city: string;
  bankName: string;
  accountNumber: string;
  upiId: string;
  ifscCode: string;
}
