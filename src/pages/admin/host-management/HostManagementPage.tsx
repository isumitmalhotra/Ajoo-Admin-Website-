import { useEffect, useMemo, useState, useCallback } from "react";
import { Box } from "@mui/material";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import { AddUserModal, ConfirmDeleteModal } from "../../../components";
import { fetchHosts } from "../../../features/admin/userManagement/host.slice";
import { deleteUser } from "../../../features/admin/userManagement/userDelete.slice";
import { HostHeader } from "./HostHeader";
import { HostTable, HostTableRow } from "./HostTable";
import CustomSnackbar from "../../../components/admin/snackbar/CustomSnackbar";
import HostDetailDialog from "./HostDetailDialog";

export default function HostManagementPage() {
  const dispatch = useAppDispatch();
  const { hosts, loading, pagination } = useAppSelector((state) => state.hosts);

  /* ================= STATE ================= */
  const [openAddHost, setOpenAddHost] = useState(false);
  const [modalMode, setModalMode] = useState<"add" | "edit">("add");
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [openDeleteModal, setOpenDeleteModal] = useState(false);
  const [deleteUserId, setDeleteUserId] = useState<number | null>(null);
  const [openHostDetail, setOpenHostDetail] = useState(false);
  const [selectedHost, setSelectedHost] = useState<HostTableRow | null>(null);

  const [page, setPage] = useState(0);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<1 | 0 | null>(null);
  const [kycStatus, setKycStatus] = useState<
    "all" | "verified" | "pending" | "rejected"
  >("all");

  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({
    open: false,
    message: "",
    severity: "success",
  });

  const rowsPerPage = 10;

  /* ================= API ================= */

  const loadHosts = useCallback(() => {
    dispatch(
      fetchHosts({
        page: page + 1,
        search,
        status,
      })
    );
  }, [dispatch, page, search, status]);

  /* ================= EFFECTS ================= */

  useEffect(() => {
    loadHosts();
  }, [loadHosts]);

  /* ================= HANDLERS ================= */

  const handleConfirmDelete = () => {
    if (!deleteUserId) return;

    dispatch(deleteUser(deleteUserId))
      .unwrap()
      .then(() => {
        loadHosts();  
      })
      .finally(() => {
        setOpenDeleteModal(false);
        setDeleteUserId(null);
      });
  };

  const handleAddHost = () => {
    setSelectedUserId(null); // 👈 empty modal
    setModalMode("add");
    setOpenAddHost(true);
  };

  const handleCloseAddHost = () => {
    setOpenAddHost(false);
  };

  const handleHostAction = (host: HostTableRow, mode: "view" | "edit") => {
    if (mode === "view") {
      setSelectedHost(host);
      setOpenHostDetail(true);
      return;
    }

    if (mode === "edit") {
      setSelectedUserId(host.id); // 👈 user_id
      setModalMode("edit");
      setOpenAddHost(true);
    }
  };

  const handleSearch = (
    searchValue: string,
    statusValue: 1 | 0 | null,
    kycStatusValue: "all" | "verified" | "pending" | "rejected"
  ) => {
    setPage(0); // reset pagination
    setSearch(searchValue);
    setStatus(statusValue);
    setKycStatus(kycStatusValue);
  };
  const handleDeleteHost = (host: HostTableRow) => {
    setDeleteUserId(host.id);
    setOpenDeleteModal(true);
  };

  /* ================= TABLE DATA ================= */

  const tableHosts: HostTableRow[] = useMemo(
    () => {
      const rows = hosts.map((h) => {
        const rawKycStatus = String(h.userKycDocs?.ud_status || "").toLowerCase();
        const derivedKycStatus: "verified" | "pending" | "rejected" =
          h.user_isVerified === 1
            ? "verified"
            : rawKycStatus.includes("reject")
            ? "rejected"
            : "pending";

        return {
        id: h.user_id,
        name: h.user_fullName,
        email: h.userCred?.cred_user_email ?? "-",
        addedAt: new Date(h.added_at).toLocaleDateString(),
        isActive: h.user_isActive === 1,
        isVerified: h.user_isVerified === 1,
        kycStatus: derivedKycStatus,
        propertyCount: h.propertyCount ?? 0,
      };
      });

      if (kycStatus === "all") {
        return rows;
      }

      return rows.filter((row) => row.kycStatus === kycStatus);
    },
    [hosts, kycStatus]
  );

  /* ================= RENDER ================= */

  return (
    <>
      <Box p={3}>
        <HostHeader
          searchTerm={search}
          status={status}
          kycStatus={kycStatus}
          onSearch={handleSearch} 
          onAdd={handleAddHost}
        />

        <HostTable
          hosts={tableHosts}
          page={page}
          rowsPerPage={rowsPerPage}
          totalPages={pagination?.totalPages || 0}
          loading={loading}
          onPageChange={setPage}
          onAction={handleHostAction}
          onDelete={handleDeleteHost}
          onRefresh={loadHosts}
        />
      </Box>
      <AddUserModal
        open={openAddHost}
        onClose={handleCloseAddHost}
        mode={modalMode}
        userId={selectedUserId ?? undefined}
        context="host"
      />

      <CustomSnackbar
        open={snackbar.open}
        message={snackbar.message}
        severity={snackbar.severity}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
      />
      <ConfirmDeleteModal
        open={openDeleteModal}
        onClose={() => {
          setOpenDeleteModal(false);
          setDeleteUserId(null);
        }}
        onConfirm={handleConfirmDelete} // 👈 HERE
        title="Delete Host"
        description="Are you sure you want to delete this host?"
      />

      <HostDetailDialog
        open={openHostDetail}
        host={selectedHost}
        onActionComplete={loadHosts}
        onClose={() => {
          setOpenHostDetail(false);
          setSelectedHost(null);
        }}
      />
    </>
  );
}
