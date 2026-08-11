import { createAsyncThunk, createSlice, type PayloadAction } from "@reduxjs/toolkit";
import api from "../../services/api";
import { ADMINENDPOINTS } from "../../services/endpoints";
import { extractApiData } from "../../services/apiContracts";

// B-04 mock-first. Real backend wired in B-08 (A-07: /host/messages/*).
const USE_HOST_MOCKS = import.meta.env.VITE_USE_HOST_MOCKS === "true";

export interface Message {
  id: string;
  sender: "HOST" | "SUPPORT";
  text: string;
  at: string;
}

export type ThreadBadge = "Payout" | "Booking" | "General";

export interface Thread {
  id: string;
  title: string;
  badge: ThreadBadge;
  unread: number;
  messages: Message[];
}

const MOCK_THREADS: Thread[] = [
  {
    id: "TH-01",
    title: "Payout settlement follow-up",
    badge: "Payout",
    unread: 2,
    messages: [
      {
        id: "m1",
        sender: "HOST",
        text: "Can you confirm the ETA for the May payout release?",
        at: "2026-05-15T09:20:00.000Z",
      },
      {
        id: "m2",
        sender: "SUPPORT",
        text: "Finance team is validating ledger entries. Expected by tomorrow evening.",
        at: "2026-05-15T10:02:00.000Z",
      },
    ],
  },
  {
    id: "TH-02",
    title: "Guest refund clarification",
    badge: "Booking",
    unread: 0,
    messages: [
      {
        id: "m3",
        sender: "SUPPORT",
        text: "Please share booking ID so we can check refund status.",
        at: "2026-05-14T12:00:00.000Z",
      },
    ],
  },
  {
    id: "TH-03",
    title: "Listing photo guidelines",
    badge: "General",
    unread: 1,
    messages: [
      {
        id: "m4",
        sender: "SUPPORT",
        text: "Your latest listing photos look great — one tip: add a wide living-room shot.",
        at: "2026-05-12T15:40:00.000Z",
      },
    ],
  },
];

interface HostCommunicationState {
  threads: Thread[];
  loading: boolean;
  error: string | null;
}

const initialState: HostCommunicationState = {
  threads: [],
  loading: false,
  error: null,
};

export const fetchHostThreads = createAsyncThunk<
  Thread[],
  void,
  { rejectValue: string }
>("hostCommunication/fetch", async () => {
  if (USE_HOST_MOCKS) return MOCK_THREADS;
  // NOTE: A-07 deliberately CUT the host messaging API (INT-08) — host-support
  // chat was folded into the support tickets system, and socket.io chat is a
  // post-sprint upgrade. There is no /host/messages/* backend, so with mocks OFF
  // the Communication Center shows an honest empty state (no failing request).
  try {
    if (!ADMINENDPOINTS.HOST_PORTAL_MESSAGES_LIST) return [];
    const res = await api.get(ADMINENDPOINTS.HOST_PORTAL_MESSAGES_LIST);
    const data = extractApiData<unknown>(res.data);
    return Array.isArray(data) ? (data as Thread[]) : [];
  } catch {
    // No backend yet → empty list (fulfilled), not an error banner.
    return [];
  }
});

const hostCommunicationSlice = createSlice({
  name: "hostCommunication",
  initialState,
  reducers: {
    // Optimistic local send; B-08 replaces with POST /host/messages/send + refetch.
    appendMessage(state, action: PayloadAction<{ threadId: string; message: Message }>) {
      const thread = state.threads.find((t) => t.id === action.payload.threadId);
      if (thread) {
        thread.messages.push(action.payload.message);
        thread.unread = 0;
      }
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchHostThreads.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHostThreads.fulfilled, (state, action) => {
        state.loading = false;
        state.threads = action.payload;
      })
      .addCase(fetchHostThreads.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || "Failed to load conversations";
        state.threads = [];
      });
  },
});

export const { appendMessage } = hostCommunicationSlice.actions;
export default hostCommunicationSlice.reducer;
