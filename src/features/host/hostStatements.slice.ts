import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { extractApiData } from "../../services/apiContracts";

// B-04 mock-first. Flips to real backend in B-08 once A-07 ships
// GET /host/statements/search. Toggle with VITE_USE_HOST_MOCKS.
const USE_HOST_MOCKS = import.meta.env.VITE_USE_HOST_MOCKS === "true";

export type StatementStatus = "READY" | "PROCESSING";

export interface StatementRow {
  id: string;
  period: string;
  generatedOn: string;
  totalBookings: number;
  grossEarnings: number;
  deductions: number;
  netPayout: number;
  status: StatementStatus;
}

const MOCK_STATEMENTS: StatementRow[] = [
  {
    id: "STM-2405",
    period: "May 2026",
    generatedOn: "2026-05-13",
    totalBookings: 18,
    grossEarnings: 214000,
    deductions: 32000,
    netPayout: 182000,
    status: "READY",
  },
  {
    id: "STM-2404",
    period: "Apr 2026",
    generatedOn: "2026-04-12",
    totalBookings: 16,
    grossEarnings: 196500,
    deductions: 27600,
    netPayout: 168900,
    status: "READY",
  },
  {
    id: "STM-2403",
    period: "Mar 2026",
    generatedOn: "2026-03-11",
    totalBookings: 14,
    grossEarnings: 173400,
    deductions: 24600,
    netPayout: 148800,
    status: "PROCESSING",
  },
];

interface HostStatementsState {
  items: StatementRow[];
  loading: boolean;
  error: string | null;
}

const initialState: HostStatementsState = {
  items: [],
  loading: false,
  error: null,
};

const num = (v: unknown) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};

// Maps A-07's /host/statements/search item (ledger-derived monthly aggregate)
// to the FE row. Backend item: { statement_id(YYYY-MM), period, totalEarnings,
// totalCommission, totalPayouts, invoiceCount, generatedAt }.
const normalizeStatement = (r: any): StatementRow => {
  const earnings = num(r.totalEarnings ?? r.grossEarnings);
  const commission = num(r.totalCommission ?? r.deductions);
  return {
    id: String(r.statement_id ?? r.id ?? r.period ?? ""),
    period: String(r.period ?? r.statement_id ?? "-"),
    generatedOn: String(r.generatedAt ?? r.generatedOn ?? r.period ?? ""),
    totalBookings: num(r.invoiceCount ?? r.totalBookings),
    grossEarnings: earnings,
    deductions: commission,
    netPayout: num(r.netPayout ?? r.totalPayouts ?? earnings - commission),
    status: (r.status as StatementStatus) ?? "READY",
  };
};

export const fetchHostStatements = createAsyncThunk<
  StatementRow[],
  void,
  { rejectValue: string }
>("hostStatements/fetch", async (_, { rejectWithValue }) => {
  if (USE_HOST_MOCKS) return MOCK_STATEMENTS;
  try {
    // A-07: POST /host/statements/search → { items, totalRecords, ... }
    const res = await api.post(ADMINENDPOINTS.HOST_PORTAL_STATEMENTS_SEARCH, {
      page: 1,
      limit: 50,
    });
    const data = extractApiData<any>(res.data);
    const items = Array.isArray(data) ? data : data?.items ?? [];
    return items.map(normalizeStatement);
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to load host statements"
      );
    }
    return rejectWithValue("Failed to load host statements");
  }
});

const hostStatementsSlice = createSlice({
  name: "hostStatements",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostStatements.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostStatements.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(fetchHostStatements.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load host statements";
        state.items = [];
      });
  },
});

export default hostStatementsSlice.reducer;
