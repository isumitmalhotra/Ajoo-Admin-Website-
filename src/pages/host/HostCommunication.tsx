import { useMemo, useState } from "react";
import {
  Avatar,
  Box,
  Button,
  Chip,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import SendRoundedIcon from "@mui/icons-material/SendRounded";

type Message = {
  id: string;
  sender: "HOST" | "SUPPORT";
  text: string;
  at: string;
};

type Thread = {
  id: string;
  title: string;
  badge: "Payout" | "Booking" | "General";
  unread: number;
  messages: Message[];
};

const INITIAL_THREADS: Thread[] = [
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
];

const badgeColor: Record<Thread["badge"], { bg: string; color: string }> = {
  Payout: { bg: "#ede9fe", color: "#5b21b6" },
  Booking: { bg: "#dbeafe", color: "#1d4ed8" },
  General: { bg: "#ecfccb", color: "#3f6212" },
};

export default function HostCommunication() {
  const [threads, setThreads] = useState<Thread[]>(INITIAL_THREADS);
  const [selectedThreadId, setSelectedThreadId] = useState<string>(INITIAL_THREADS[0]?.id || "");
  const [draft, setDraft] = useState("");

  const selectedThread = useMemo(
    () => threads.find((thread) => thread.id === selectedThreadId) || null,
    [selectedThreadId, threads]
  );

  const handleSend = () => {
    if (!draft.trim() || !selectedThread) return;
    const newMessage: Message = {
      id: `m-${Date.now()}`,
      sender: "HOST",
      text: draft.trim(),
      at: new Date().toISOString(),
    };

    setThreads((prev) =>
      prev.map((thread) =>
        thread.id === selectedThread.id
          ? { ...thread, messages: [...thread.messages, newMessage], unread: 0 }
          : thread
      )
    );
    setDraft("");
  };

  return (
    <Stack spacing={2}>
      <Paper
        elevation={0}
        sx={{
          p: 2.5,
          borderRadius: "1rem",
          border: "1px solid #ede9fe",
          boxShadow: "0 12px 28px rgba(17,24,39,0.05)",
        }}
      >
        <Typography variant="h6" fontWeight={800}>
          Communication Center
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Keep all host conversations with support and operations in one place.
        </Typography>
      </Paper>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "320px 1fr" },
          gap: 1.3,
        }}
      >
        <Paper elevation={0} sx={{ borderRadius: "1rem", border: "1px solid #ede9fe", p: 1.25 }}>
          <Typography variant="subtitle2" fontWeight={800} sx={{ px: 1, py: 0.5 }}>
            Conversations
          </Typography>
          <Stack spacing={0.8}>
            {threads.map((thread) => (
              <Box
                key={thread.id}
                onClick={() => setSelectedThreadId(thread.id)}
                sx={{
                  p: 1.1,
                  borderRadius: "0.75rem",
                  border: selectedThreadId === thread.id ? "1px solid #c4b5fd" : "1px solid #e5e7eb",
                  bgcolor: selectedThreadId === thread.id ? "#faf5ff" : "#ffffff",
                  cursor: "pointer",
                  transition: "all .2s ease",
                }}
              >
                <Stack direction="row" justifyContent="space-between" alignItems="center">
                  <Typography variant="body2" fontWeight={700}>
                    {thread.title}
                  </Typography>
                  {thread.unread > 0 ? (
                    <Chip size="small" label={thread.unread} sx={{ bgcolor: "#fee2e2", color: "#b91c1c" }} />
                  ) : null}
                </Stack>
                <Chip
                  size="small"
                  label={thread.badge}
                  sx={{
                    mt: 0.7,
                    bgcolor: badgeColor[thread.badge].bg,
                    color: badgeColor[thread.badge].color,
                    fontWeight: 700,
                  }}
                />
              </Box>
            ))}
          </Stack>
        </Paper>

        <Paper
          elevation={0}
          sx={{
            borderRadius: "1rem",
            border: "1px solid #ede9fe",
            p: 1.4,
            minHeight: 420,
            display: "flex",
            flexDirection: "column",
          }}
        >
          {!selectedThread ? (
            <Typography variant="body2" color="text.secondary">
              Select a conversation to start messaging.
            </Typography>
          ) : (
            <>
              <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.2}>
                <Typography variant="subtitle1" fontWeight={800}>
                  {selectedThread.title}
                </Typography>
                <Chip
                  size="small"
                  label={selectedThread.badge}
                  sx={{
                    bgcolor: badgeColor[selectedThread.badge].bg,
                    color: badgeColor[selectedThread.badge].color,
                  }}
                />
              </Stack>

              <Stack spacing={0.9} sx={{ flex: 1, overflowY: "auto", pr: 0.3 }}>
                {selectedThread.messages.map((message) => {
                  const isHost = message.sender === "HOST";
                  return (
                    <Stack
                      key={message.id}
                      direction="row"
                      spacing={1}
                      justifyContent={isHost ? "flex-end" : "flex-start"}
                    >
                      {!isHost ? (
                        <Avatar sx={{ width: 28, height: 28, bgcolor: "#6d28d9", fontSize: "0.7rem" }}>
                          S
                        </Avatar>
                      ) : null}
                      <Box
                        sx={{
                          maxWidth: "75%",
                          p: 1,
                          borderRadius: "0.75rem",
                          bgcolor: isHost ? "#ede9fe" : "#f3f4f6",
                          color: "#1f2937",
                        }}
                      >
                        <Typography variant="body2">{message.text}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {new Date(message.at).toLocaleString("en-IN")}
                        </Typography>
                      </Box>
                    </Stack>
                  );
                })}
              </Stack>

              <Stack direction="row" spacing={1} mt={1.2}>
                <TextField
                  fullWidth
                  size="small"
                  placeholder="Type your message..."
                  value={draft}
                  onChange={(event) => setDraft(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      handleSend();
                    }
                  }}
                />
                <Button
                  variant="contained"
                  onClick={handleSend}
                  disabled={!draft.trim()}
                  sx={{ bgcolor: "#6d28d9" }}
                >
                  <SendRoundedIcon fontSize="small" />
                </Button>
              </Stack>
            </>
          )}
        </Paper>
      </Box>
    </Stack>
  );
}
