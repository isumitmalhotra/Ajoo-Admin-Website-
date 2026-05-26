import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type {
  Invoice,
  InvoiceSearchPayload,
  PaginatedState,
} from "../../../pages/admin/finance/types";
import {
  getFinanceDataNode,
  getPage,
  getTotalPages,
  getTotalRecords,
  normalizeInvoiceRows,
} from "../../../services/financeContracts";

const initialState: PaginatedState<Invoice> = {
  data: [],
  totalRecords: 0,
  currentPage: 1,
  totalPages: 1,
  loading: false,
  error: null,
};

export const fetchInvoiceList = createAsyncThunk<
  {
    invoices: Invoice[];
    totalRecords: number;
    currentPage: number;
    totalPages: number;
  },
  InvoiceSearchPayload | void,
  { rejectValue: string }
>("finance/fetchInvoiceList", async (payload, { rejectWithValue }) => {
  try {
    const res = await api.post(
      ADMINENDPOINTS.FINANCE_INVOICE_SEARCH,
      payload ?? { page: 1, limit: 10 }
    );
    const d = getFinanceDataNode(res.data);
    const invoices = normalizeInvoiceRows(d?.invoices ?? d?.rows ?? []);
    return {
      invoices,
      totalRecords: getTotalRecords(d, invoices.length),
      currentPage: getPage(d, (payload as InvoiceSearchPayload)?.page ?? 1),
      totalPages: getTotalPages(d),
    };
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      if (err.response?.status === 404) {
        return {
          invoices: [],
          totalRecords: 0,
          currentPage: (payload as InvoiceSearchPayload)?.page ?? 1,
          totalPages: 1,
        };
      }
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch invoices"
      );
    }
    return rejectWithValue("Failed to fetch invoices");
  }
});

const invoiceListSlice = createSlice({
  name: "invoiceList",
  initialState,
  reducers: {
    resetInvoiceList: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchInvoiceList.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchInvoiceList.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.invoices;
        state.totalRecords = action.payload.totalRecords;
        state.currentPage = action.payload.currentPage;
        state.totalPages = action.payload.totalPages;
      })
      .addCase(fetchInvoiceList.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
        state.data = [];
      });
  },
});

export const { resetInvoiceList } = invoiceListSlice.actions;
export default invoiceListSlice.reducer;
