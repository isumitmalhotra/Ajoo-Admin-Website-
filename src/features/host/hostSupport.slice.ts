import { createAsyncThunk, createSlice, type PayloadAction } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { extractApiData } from "../../services/apiContracts";

// B-04 mock-first. Real backend wired in B-08 (A-07: /host/support/tickets/*).
const USE_HOST_MOCKS = import.meta.env.VITE_USE_HOST_MOCKS === "true";

export type TicketPriority = "LOW" | "MEDIUM" | "HIGH";
export type TicketStatus = "OPEN" | "IN_PROGRESS" | "RESOLVED";

export interface Ticket {
  id: string;
  subject: string;
  category: string;
  priority: TicketPriority;
  status: TicketStatus;
  updatedAt: string;
  lastMessage: string;
}

const MOCK_TICKETS: Ticket[] = [
  {
    id: "TCK-2191",
    subject: "Payout not reflecting in dashboard",
    category: "Payout",
    priority: "HIGH",
    status: "IN_PROGRESS",
    updatedAt: "2026-05-15T10:20:00.000Z",
    lastMessage: "Support asked for booking references.",
  },
  {
    id: "TCK-2178",
    subject: "Need invoice correction for Apr payout",
    category: "Invoice",
    priority: "MEDIUM",
    status: "OPEN",
    updatedAt: "2026-05-14T08:42:00.000Z",
    lastMessage: "Ticket created and assigned to finance queue.",
  },
  {
    id: "TCK-2101",
    subject: "Guest cancellation policy clarification",
    category: "Booking",
    priority: "LOW",
    status: "RESOLVED",
    updatedAt: "2026-05-09T12:16:00.000Z",
    lastMessage: "Policy explanation shared and acknowledged.",
  },
];

interface HostSupportState {
  tickets: Ticket[];
  loading: boolean;
  error: string | null;
}

const initialState: HostSupportState = {
  tickets: [],
  loading: false,
  error: null,
};

// A-07 tbl_support_tickets row → FE Ticket. Backend has no priority column and
// keeps messages in a separate table, so those default gracefully.
const normalizeTicket = (r: any): Ticket => ({
  id: String(r.st_id ?? r.id ?? r.ticket_id ?? ""),
  subject: String(r.st_subject ?? r.subject ?? "(no subject)"),
  category: String(r.st_category ?? r.category ?? "General"),
  priority: (r.st_priority ?? r.priority ?? "MEDIUM") as TicketPriority,
  status: (r.st_status ?? r.status ?? "OPEN") as TicketStatus,
  updatedAt: String(
    r.st_last_reply_at ?? r.st_updated_at ?? r.st_created_at ?? new Date().toISOString()
  ),
  lastMessage: String(r.st_last_message ?? r.lastMessage ?? ""),
});

export const fetchHostTickets = createAsyncThunk<
  Ticket[],
  void,
  { rejectValue: string }
>("hostSupport/fetch", async (_, { rejectWithValue }) => {
  if (USE_HOST_MOCKS) return MOCK_TICKETS;
  try {
    // A-07: POST /host/support/tickets/search → { items, totalRecords, ... }
    const res = await api.post(ADMINENDPOINTS.HOST_PORTAL_SUPPORT_TICKETS_SEARCH, {
      page: 1,
      limit: 50,
    });
    const data = extractApiData<any>(res.data);
    const items = Array.isArray(data) ? data : data?.items ?? [];
    return items.map(normalizeTicket);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to load support tickets"
      );
    }
    return rejectWithValue("Failed to load support tickets");
  }
});

// Real ticket creation (A-07 POST /host/support/tickets/create) then refetch.
export const createHostTicket = createAsyncThunk<
  void,
  { subject: string; category: string; message: string },
  { rejectValue: string }
>("hostSupport/create", async (payload, { dispatch, rejectWithValue }) => {
  if (USE_HOST_MOCKS) return; // page handles optimistic local insert under mocks
  try {
    await api.post(ADMINENDPOINTS.HOST_PORTAL_SUPPORT_TICKETS_CREATE, payload);
    await dispatch(fetchHostTickets());
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(err.response?.data?.message || "Failed to create ticket");
    }
    return rejectWithValue("Failed to create ticket");
  }
});

const hostSupportSlice = createSlice({
  name: "hostSupport",
  initialState,
  reducers: {
    // Optimistic local insert; B-08 replaces with a POST + refetch.
    addTicket(state, action: PayloadAction<Ticket>) {
      state.tickets.unshift(action.payload);
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostTickets.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostTickets.fulfilled, (state, action) => {
        state.loading = false;
        state.tickets = action.payload;
      })
      .addCase(fetchHostTickets.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load support tickets";
        state.tickets = [];
      });
  },
});

export const { addTicket } = hostSupportSlice.actions;
export default hostSupportSlice.reducer;
