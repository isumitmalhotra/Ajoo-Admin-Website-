import { useState } from "react";
import {
  Box,
  Chip,
  Paper,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tooltip,
} from "@mui/material";
import { Pagination } from "../../../components";
import { HostActions } from "./HostActions";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { updateHostStatus } from "../../../features/admin/userManagement/userStatusUpdate.slice";
import { TableLoader } from "../../../components/admin/common/TableLoader";
import CustomSnackbar from "../../../components/admin/snackbar/CustomSnackbar";

/* ================= CONSTANTS ================= */

const COLORS = {
  text: { secondary: "#6b7280" },
  primary: "#881f9b",
};

/* ================= TYPES ================= */

export interface HostTableRow {
  id: number;
  name: string;
  email: string;
  propertyCount: number;
  isVerified: boolean;
  kycStatus: "verified" | "pending" | "rejected";
  isActive: boolean;
  addedAt: string;
}

interface Props {
  hosts: HostTableRow[];
  page: number;
  rowsPerPage: number;
  totalPages: number;
  loading: boolean;
  onPageChange: (page: number) => void;
  onAction: (host: HostTableRow, mode: "view" | "edit") => void;
  onDelete: (host: HostTableRow) => void;
  onRefresh: () => void; // 🔁 re-fetch hosts
}

/* ================= COMPONENT ================= */

export const HostTable = ({
  hosts,
  page,
  rowsPerPage,
  totalPages,
  onPageChange,
  onAction,
  onDelete,
  onRefresh,
}: Props) => {
  const dispatch = useAppDispatch();

  const { loading } = useAppSelector((state) => state.hosts);
  const { loading: statusUpdating } = useAppSelector(
    (state) => state.userStatusUpdate
  );

  /* ---------- Optimistic toggle state ---------- */
  const [optimisticStatus, setOptimisticStatus] = useState<
    Record<number, boolean>
  >({});

  /* ---------- Snackbar state ---------- */
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({
    open: false,
    message: "",
    severity: "success",
  });

  /* ================= HANDLERS ================= */

  const handleStatusToggle = (hostId: number, checked: boolean) => {
    setOptimisticStatus((prev) => ({
      ...prev,
      [hostId]: checked,
    }));

    dispatch(
      updateHostStatus({
        hostId,
        isActive: checked ? 1 : 0,
      })
    )
      .unwrap()
      .then(() => {
        setSnackbar({
          open: true,
          message: checked
            ? "Host activated successfully"
            : "Host deactivated successfully",
          severity: "success",
        });

        onRefresh();
      })
      .catch((error) => {
        setOptimisticStatus((prev) => ({
          ...prev,
          [hostId]: !checked,
        }));

        const errorMessage =
          typeof error === "string"
            ? error
            : error?.message || "Failed to update host status";

        setSnackbar({
          open: true,
          message: errorMessage,
          severity: "error",
        });
      });
  };

  /* ================= RENDER ================= */

  return (
    <Paper elevation={0} sx={{ borderRadius: 3, overflow: "hidden" }}>
      <TableContainer sx={{ position: "relative" }}>
        <Table>
          <TableHead sx={{ backgroundColor: "#f9fafb" }}>
            <TableRow>
              {[
                "ID",
                "NAME",
                "EMAIL",
                "PROPERTIES",
                "VERIFICATION",
                "CREATED",
                "STATUS",
                "ACTIONS",
              ].map((h) => (
                <TableCell
                  key={h}
                  sx={{ fontWeight: 600, color: COLORS.text.secondary }}
                >
                  {h}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>

          <TableBody>
            {loading && (
              <TableRow>
                <TableCell colSpan={8} align="center">
                  <TableLoader />
                </TableCell>
              </TableRow>
            )}
            {statusUpdating && (
              <Box
                sx={{
                  position: "absolute",
                  inset: 0,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  backgroundColor: "rgba(255,255,255,0.6)",
                  zIndex: 10,
                }}
              >
                <TableLoader />
              </Box>
            )}
            {!loading && hosts.length === 0 && (
              <TableRow>
                <TableCell colSpan={8} align="center">
                  No hosts found
                </TableCell>
              </TableRow>
            )}
            {!loading &&
              hosts.map((host, index) => {
                const checked =
                  optimisticStatus[host.id] !== undefined
                    ? optimisticStatus[host.id]
                    : host.isActive;

                return (
                  <TableRow key={host.id} hover>
                    <TableCell>
                      {page * rowsPerPage + index + 1}
                    </TableCell>

                    <TableCell>{host.name}</TableCell>
                    <TableCell>{host.email}</TableCell>

                    <TableCell>
                      <Chip
                        label={`${host.propertyCount} Properties`}
                        size="small"
                        sx={{
                          backgroundColor: "#EEF2FF",
                          color: "#3730A3",
                          fontWeight: 500,
                        }}
                      />
                    </TableCell>

                    <TableCell>
                      <Chip
                        label={host.isVerified ? "Verified" : "Unverified"}
                        size="small"
                        sx={{
                          backgroundColor: host.isVerified
                            ? "#D1FAE5"
                            : "#FEF3C7",
                          color: host.isVerified ? "#065F46" : "#92400E",
                          fontWeight: 600,
                        }}
                      />
                    </TableCell>

                    <TableCell>{host.addedAt}</TableCell>

                    <TableCell>
                      <Tooltip
                        title={
                          checked
                            ? "Deactivate Host"
                            : "Activate Host"
                        }
                      >
                        <Switch
                          checked={checked}
                          onChange={(e) =>
                            handleStatusToggle(
                              host.id,
                              e.target.checked
                            )
                          }
                          sx={{
                            "& .MuiSwitch-switchBase.Mui-checked": {
                              color: COLORS.primary,
                            },
                            "& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track":
                              {
                                backgroundColor: COLORS.primary,
                              },
                          }}
                        />
                      </Tooltip>
                    </TableCell>

                    <TableCell>
                      <HostActions
                        host={host}
                        onAction={onAction}
                        onDelete={onDelete}
                      />
                    </TableCell>
                  </TableRow>
                );
              })}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      <Box display="flex" justifyContent="center" p={2}>
        <Pagination
          count={totalPages}
          page={page + 1}
          onChange={(_, v) => onPageChange(v - 1)}
        />
      </Box>
      <CustomSnackbar
        open={snackbar.open}
        message={snackbar.message}
        severity={snackbar.severity}
        onClose={() =>
          setSnackbar((prev) => ({ ...prev, open: false }))
        }
      />
    </Paper>
  );
};
