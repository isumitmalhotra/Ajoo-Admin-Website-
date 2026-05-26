import { useMemo, useState } from "react";
import {
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import AddRoundedIcon from "@mui/icons-material/AddRounded";

type TicketPriority = "LOW" | "MEDIUM" | "HIGH";
type TicketStatus = "OPEN" | "IN_PROGRESS" | "RESOLVED";

type Ticket = {
  id: string;
  subject: string;
  category: string;
  priority: TicketPriority;
  status: TicketStatus;
  updatedAt: string;
  lastMessage: string;
};

const INITIAL_TICKETS: Ticket[] = [
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

const statusColorMap: Record<TicketStatus, { bg: string; color: string }> = {
  OPEN: { bg: "#fef3c7", color: "#92400e" },
  IN_PROGRESS: { bg: "#dbeafe", color: "#1d4ed8" },
  RESOLVED: { bg: "#dcfce7", color: "#166534" },
};

const priorityColorMap: Record<TicketPriority, { bg: string; color: string }> = {
  LOW: { bg: "#ecfeff", color: "#0e7490" },
  MEDIUM: { bg: "#fef9c3", color: "#a16207" },
  HIGH: { bg: "#fee2e2", color: "#b91c1c" },
};

export default function HostSupport() {
  const [tickets, setTickets] = useState<Ticket[]>(INITIAL_TICKETS);
  const [statusFilter, setStatusFilter] = useState<"ALL" | TicketStatus>("ALL");
  const [createOpen, setCreateOpen] = useState(false);
  const [subject, setSubject] = useState("");
  const [category, setCategory] = useState("General");
  const [priority, setPriority] = useState<TicketPriority>("MEDIUM");
  const [message, setMessage] = useState("");

  const filteredTickets = useMemo(() => {
    if (statusFilter === "ALL") return tickets;
    return tickets.filter((ticket) => ticket.status === statusFilter);
  }, [statusFilter, tickets]);

  const handleCreate = () => {
    if (!subject.trim() || !message.trim()) return;
    const nextTicket: Ticket = {
      id: `TCK-${Math.floor(2000 + Math.random() * 8000)}`,
      subject: subject.trim(),
      category,
      priority,
      status: "OPEN",
      updatedAt: new Date().toISOString(),
      lastMessage: message.trim(),
    };
    setTickets((prev) => [nextTicket, ...prev]);
    setSubject("");
    setCategory("General");
    setPriority("MEDIUM");
    setMessage("");
    setCreateOpen(false);
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
        <Stack
          direction={{ xs: "column", md: "row" }}
          spacing={1.4}
          alignItems={{ xs: "flex-start", md: "center" }}
          justifyContent="space-between"
        >
          <Box>
            <Typography variant="h6" fontWeight={800}>
              Host Support Desk
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Raise support tickets, monitor their status, and track responses.
            </Typography>
          </Box>
          <Stack direction="row" spacing={1}>
            <TextField
              select
              size="small"
              label="Status"
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value as "ALL" | TicketStatus)}
              sx={{ minWidth: 170 }}
            >
              <MenuItem value="ALL">All</MenuItem>
              <MenuItem value="OPEN">Open</MenuItem>
              <MenuItem value="IN_PROGRESS">In Progress</MenuItem>
              <MenuItem value="RESOLVED">Resolved</MenuItem>
            </TextField>
            <Button
              variant="contained"
              startIcon={<AddRoundedIcon />}
              onClick={() => setCreateOpen(true)}
              sx={{ textTransform: "none", fontWeight: 700, bgcolor: "#6d28d9" }}
            >
              New Ticket
            </Button>
          </Stack>
        </Stack>
      </Paper>

      <Paper elevation={0} sx={{ p: 2, borderRadius: "1rem", border: "1px solid #ede9fe" }}>
        {filteredTickets.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ p: 1 }}>
            No support tickets found for the selected status.
          </Typography>
        ) : (
          <Stack spacing={1.15}>
            {filteredTickets.map((ticket) => (
              <Box
                key={ticket.id}
                sx={{
                  p: 1.4,
                  borderRadius: "0.8rem",
                  border: "1px solid #e5e7eb",
                  bgcolor: "#ffffff",
                }}
              >
                <Stack
                  direction={{ xs: "column", sm: "row" }}
                  spacing={1}
                  alignItems={{ xs: "flex-start", sm: "center" }}
                  justifyContent="space-between"
                >
                  <Box>
                    <Typography variant="subtitle2" fontWeight={800}>
                      {ticket.subject}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {ticket.id} • {ticket.category} • Updated{" "}
                      {new Date(ticket.updatedAt).toLocaleString("en-IN")}
                    </Typography>
                  </Box>
                  <Stack direction="row" spacing={0.8}>
                    <Chip
                      size="small"
                      label={ticket.priority.replace("_", " ")}
                      sx={{
                        bgcolor: priorityColorMap[ticket.priority].bg,
                        color: priorityColorMap[ticket.priority].color,
                        fontWeight: 700,
                      }}
                    />
                    <Chip
                      size="small"
                      label={ticket.status.replace("_", " ")}
                      sx={{
                        bgcolor: statusColorMap[ticket.status].bg,
                        color: statusColorMap[ticket.status].color,
                        fontWeight: 700,
                      }}
                    />
                  </Stack>
                </Stack>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 0.8 }}>
                  {ticket.lastMessage}
                </Typography>
              </Box>
            ))}
          </Stack>
        )}
      </Paper>

      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Create Support Ticket</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={1.3}>
            <TextField
              label="Subject"
              size="small"
              fullWidth
              value={subject}
              onChange={(event) => setSubject(event.target.value)}
            />
            <Stack direction={{ xs: "column", sm: "row" }} spacing={1}>
              <TextField
                label="Category"
                size="small"
                fullWidth
                value={category}
                onChange={(event) => setCategory(event.target.value)}
              />
              <TextField
                select
                label="Priority"
                size="small"
                fullWidth
                value={priority}
                onChange={(event) => setPriority(event.target.value as TicketPriority)}
              >
                <MenuItem value="LOW">Low</MenuItem>
                <MenuItem value="MEDIUM">Medium</MenuItem>
                <MenuItem value="HIGH">High</MenuItem>
              </TextField>
            </Stack>
            <TextField
              multiline
              minRows={4}
              label="Describe your issue"
              value={message}
              onChange={(event) => setMessage(event.target.value)}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateOpen(false)}>Cancel</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={!subject.trim() || !message.trim()}
            sx={{ bgcolor: "#6d28d9" }}
          >
            Submit Ticket
          </Button>
        </DialogActions>
      </Dialog>
    </Stack>
  );
}
