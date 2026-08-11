import { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Avatar,
  Box,
  Button,
  Chip,
  CircularProgress,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import SendRoundedIcon from "@mui/icons-material/SendRounded";
import { useAppDispatch, useAppSelector } from "../../app/hooks";
import {
  fetchHostThreads,
  appendMessage,
  type Message,
  type ThreadBadge,
} from "../../features/host/hostCommunication.slice";

const badgeColor: Record<ThreadBadge, { bg: string; color: string }> = {
  Payout: { bg: "#FFFAF0", color: "#1B2447" },
  Booking: { bg: "#dbeafe", color: "#1d4ed8" },
  General: { bg: "#ecfccb", color: "#3f6212" },
};

export default function HostCommunication() {
  const dispatch = useAppDispatch();
  const { threads, loading, error } = useAppSelector((state) => state.hostCommunication);
  const [selectedThreadId, setSelectedThreadId] = useState<string>("");
  const [draft, setDraft] = useState("");

  useEffect(() => {
    dispatch(fetchHostThreads());
  }, [dispatch]);

  // Auto-select the first thread once threads arrive (and keep selection valid).
  useEffect(() => {
    if (threads.length > 0 && !threads.some((t) => t.id === selectedThreadId)) {
      setSelectedThreadId(threads[0].id);
    }
  }, [threads, selectedThreadId]);

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

    dispatch(appendMessage({ threadId: selectedThread.id, message: newMessage }));
    setDraft("");
  };

  return (
    <Stack spacing={2}>
      <Paper
        elevation={0}
        sx={{
          p: 2.5,
          borderRadius: "1rem",
          border: "1px solid #FFFAF0",
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
        <Paper elevation={0} sx={{ borderRadius: "1rem", border: "1px solid #FFFAF0", p: 1.25 }}>
          <Typography variant="subtitle2" fontWeight={800} sx={{ px: 1, py: 0.5 }}>
            Conversations
          </Typography>
          {error && (
            <Alert severity="error" sx={{ m: 0.5, borderRadius: "0.6rem" }}>
              {error}
            </Alert>
          )}
          {loading ? (
            <Box sx={{ display: "flex", justifyContent: "center", p: 3 }}>
              <CircularProgress size={22} sx={{ color: "#2A356B" }} />
            </Box>
          ) : threads.length === 0 ? (
            <Typography variant="body2" color="text.secondary" sx={{ px: 1, py: 2 }}>
              No conversations yet.
            </Typography>
          ) : (
          <Stack spacing={0.8}>
            {threads.map((thread) => (
              <Box
                key={thread.id}
                onClick={() => setSelectedThreadId(thread.id)}
                sx={{
                  p: 1.1,
                  borderRadius: "0.75rem",
                  border: selectedThreadId === thread.id ? "1px solid #D9CFB8" : "1px solid #e5e7eb",
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
          )}
        </Paper>

        <Paper
          elevation={0}
          sx={{
            borderRadius: "1rem",
            border: "1px solid #FFFAF0",
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
                        <Avatar sx={{ width: 28, height: 28, bgcolor: "#2A356B", fontSize: "0.7rem" }}>
                          S
                        </Avatar>
                      ) : null}
                      <Box
                        sx={{
                          maxWidth: "75%",
                          p: 1,
                          borderRadius: "0.75rem",
                          bgcolor: isHost ? "#FFFAF0" : "#f3f4f6",
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
                  sx={{ bgcolor: "#2A356B" }}
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
