import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";
import axios from "axios";
import api from "../../../services/api";
import { ADMINENDPOINTS } from "../../../services/endpoints";
import type { Invoice, DetailState } from "../../../pages/admin/finance/types";

const initialState: DetailState<Invoice> = {
  data: null,
  loading: false,
  error: null,
};

export const fetchInvoiceDetail = createAsyncThunk<
  Invoice,
  number,
  { rejectValue: string }
>("finance/fetchInvoiceDetail", async (invoiceId, { rejectWithValue }) => {
  try {
    const res = await api.get(
      `${ADMINENDPOINTS.FINANCE_INVOICE_BY_ID}/${invoiceId}`
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to fetch invoice detail"
      );
    }
    return rejectWithValue("Failed to fetch invoice detail");
  }
});

export const voidInvoice = createAsyncThunk<
  Invoice,
  { invoiceId: number; reason: string },
  { rejectValue: string }
>("finance/voidInvoice", async ({ invoiceId, reason }, { rejectWithValue }) => {
  try {
    const res = await api.post(
      `${ADMINENDPOINTS.FINANCE_INVOICE_VOID}/${invoiceId}`,
      { reason }
    );
    return res.data.data;
  } catch (err: unknown) {
    if (axios.isAxiosError(err)) {
      return rejectWithValue(
        err.response?.data?.message || "Failed to void invoice"
      );
    }
    return rejectWithValue("Failed to void invoice");
  }
});

const invoiceDetailSlice = createSlice({
  name: "invoiceDetail",
  initialState,
  reducers: {
    resetInvoiceDetail: () => initialState,
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchInvoiceDetail.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchInvoiceDetail.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchInvoiceDetail.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed";
      })
      .addCase(voidInvoice.fulfilled, (state, action) => {
        state.data = action.payload;
      });
  },
});

export const { resetInvoiceDetail } = invoiceDetailSlice.actions;
export default invoiceDetailSlice.reducer;
