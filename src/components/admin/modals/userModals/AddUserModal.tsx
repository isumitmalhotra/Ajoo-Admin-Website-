import React, { useEffect, useMemo, useRef } from "react";
import { Modal, Box, Typography, Button, IconButton } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { Formik, Form } from "formik";
import { motion, AnimatePresence } from "framer-motion";
import { TableLoader } from "../../common/TableLoader";
import { useAppDispatch, useAppSelector } from "../../../../app/hooks";
// import { useAppDispatch } from "../../../../app/hooks";
import { validationSchemaAddUserHostModal } from "../../../../validations/admin-validations";
import { PurpleThemeColor } from "../../../../theme/themeColor";
import { getUserById } from "../../../../features/admin/userManagement/userDetails.slice";
import { fetchUsers } from "../../../../features/admin/userManagement/user.slice";
import { fetchHosts } from "../../../../features/admin/userManagement/host.slice";
import { addOrUpdateUser } from "../../../../features/admin/userManagement/userAddUpdate.slice";
import CustomSnackbar from "../../snackbar/CustomSnackbar";

import PersonalInfo from "./PersonalInfo";
import AddressInfo from "./AddressInfo";
import AccountStatus from "./AccountStatus";
import RoleSelector from "./RoleSelector";
import ProfileUpload from "./ProfileUpload";
import IdUpload from "./IdUpload";

export const initialValues = {
  fullName: "",
  email: "",
  phone: "",
  password: "",
  dob: "",
  address: "",
  city: "",
  zipcode: "",
  status: 1,
  verified: 1,
  documentType: "",
  documentNumber: "",
  user: true,
  host: false,
  profileImage: "",
  profileImageFileId: null,
  idImage: "",
  idImageFileId: null,
};

interface AddUserModalProps {
  open: boolean;
  onClose: () => void;
  // onAddUser: (data: any) => void;
  mode: "add" | "edit" | "view";
  userId?: number;
  context: "user" | "host"; // ✅ NEW
}

const AddUserModal: React.FC<AddUserModalProps> = ({
  open,
  onClose,
  // onAddUser,
  mode,
  context,
  userId,
}) => {
  const dispatch = useAppDispatch();
  const { loading: submitLoading } = useAppSelector(
    (state) => state.userAddUpdate
  );
  const { data, loading } = useAppSelector((state) => state.userDetails);
  const { loading: imgDeleteLoading } = useAppSelector(
    (state) => state.userImageDelete
  );
  const [snackbar, setSnackbar] = React.useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });

  const isViewMode = mode === "view";

  /* ---------------- API → Form mapping ---------------- */
  const mapApiToFormValues = (data: any) => ({
    fullName: data?.user_fullName ?? "",
    email: data?.userCred?.cred_user_email ?? "",
    phone: data?.user_pnumber ?? "",
    dob: data?.user_dob ?? "",
    address: data?.user_address ?? "",
    city: data?.user_city ?? "",
    zipcode: data?.user_zipcode ?? "",
    status: data?.user_isActive ?? 1,
    verified: data?.user_isVerified ?? 1,
    documentType: data?.userKycDocs?.ud_acc_doc_id ?? "",
    documentNumber: data?.userKycDocs?.ud_number ?? "",
    user: data?.user_isUser === 1,
    host: data?.user_isHost === 1,
    profileImage: data?.profileImage?.url ?? "",
    profileImageFileId: data?.profileImage?.afile_id ?? null,
    idImage: data?.kycDocumentImage?.url ?? "",
    idImageFileId: data?.kycDocumentImage?.afile_id ?? null,
    password: "",
  });

  /* ---------------- Fetch user ---------------- */
  useEffect(() => {
    if ((mode === "edit" || mode === "view") && userId && open) {
      dispatch(getUserById(userId));
    }
  }, [dispatch, mode, userId, open]);

  /* ---------------- Initial values ---------------- */
  const formInitialValues = useMemo(() => {
    if (mode === "add") {
      return {
        ...initialValues,
        host: context === "host",
        user: true,
      };
    }

    return data ? mapApiToFormValues(data) : initialValues;
  }, [mode, data, context]);

  /* ---------------- Store original values ---------------- */
  const initialRef = useRef<any>(null);

  useEffect(() => {
    if (data) {
      initialRef.current = mapApiToFormValues(data);
    }
  }, [data]);

  /* ---------------- Modal title (NO Formik dependency) ---------------- */
  const modalTitle = useMemo(() => {
    if (mode === "add") return "Add New User";
    if (mode === "edit") return "Edit User";
    return "User Details";
  }, [mode]);

  /* ---------------- Submit handler ---------------- */
  const handleSubmit = (values: any) => {
    if (isViewMode) return;

    const formData = new FormData();
    if (userId) formData.append("userId", String(userId));

    const payloadMap: Record<string, string> = {
      fullName: "user_fullName",
      phone: "user_pnumber",
      dob: "user_dob",
      address: "user_address",
      city: "user_city",
      zipcode: "user_zipcode",
      host: "user_isHost",
      user: "user_isUser",
      status: "user_isActive",
      verified: "user_isVerified",
      password: "cred_user_password",
      email: "cred_user_email",
      documentType: "cred_user_doc_type",
      documentNumber: "cred_user_doc_number",
    };

    Object.keys(values).forEach((key) => {
      const value = values[key];

      // images
      if (key === "profileImage" && value instanceof File) {
        formData.append("user_profile", value);
        return;
      }
      if (key === "idImage" && value instanceof File) {
        formData.append("user_id_image", value);
        return;
      }

      // booleans → 1/0
      if (typeof value === "boolean") {
        formData.append(payloadMap[key]!, value ? "1" : "0");
        return;
      }

      // normal fields
      if (value !== undefined && value !== null && payloadMap[key]) {
        formData.append(payloadMap[key]!, String(value));
      }
    });

    dispatch(addOrUpdateUser(formData))
      .unwrap()
      .then(() => {
        if (context === "host") {
          dispatch(
            fetchHosts({
              page: 1,
              search: "",
              status: null,
            })
          );
        } else {
          dispatch(fetchUsers({ page: 1, search: "" }));
          setSnackbar({
            open: true,
            message: "User updated successfully!",
            severity: "success",
          });
        }
        onClose(); // close modal after success
      })
      .catch((err: any) => {
        setSnackbar({
          open: true,
          message: err?.message || "Failed to update user",
          severity: "error",
        });
      });
  };

  /* ------------------------------------------------------------------ */
  return (
    <>
      <AnimatePresence>
        {open && (
          <Modal open={open} onClose={onClose}>
            <motion.div
              key="add-user-modal"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.25 }}
              style={styles.motionWrapper}
            >
              <Box sx={styles.container}>
                <Box sx={{ position: "relative" }}>
                  {/* Loader overlay */}
                  {(loading || submitLoading || imgDeleteLoading) && (
                    <Box
                      sx={{
                        position: "absolute",
                        inset: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        backgroundColor: "rgba(255,255,255,0.7)",
                        zIndex: 10,
                      }}
                    >
                      <TableLoader />
                    </Box>
                  )}

                  {/* Form */}
                  <Formik
                    initialValues={formInitialValues}
                    validationSchema={validationSchemaAddUserHostModal}
                    enableReinitialize
                    onSubmit={handleSubmit}
                  >
                    <Form>
                      {/* HEADER */}
                      <Box sx={styles.header}>
                        <Typography sx={styles.title}>{modalTitle}</Typography>
                        <IconButton onClick={onClose} sx={styles.closeBtn}>
                          <CloseIcon />
                        </IconButton>
                      </Box>

                      {/* FORM SECTIONS */}
                      <Box sx={styles.formGrid}>
                        <PersonalInfo disabled={isViewMode} />
                        <AddressInfo disabled={isViewMode} />
                        <AccountStatus disabled={isViewMode} />
                        <RoleSelector disabled={isViewMode} />
                      </Box>

                      <ProfileUpload disabled={isViewMode} userId={userId} />
                      <IdUpload disabled={isViewMode} userId={userId} />

                      {/* ACTIONS */}
                      {!isViewMode && (
                        <Box sx={styles.actions}>
                          <Button
                            onClick={onClose}
                            variant="outlined"
                            sx={{
                              borderColor: "#1B2447",
                              color: "#1B2447",
                              "&:hover": {
                                borderColor: "#1B2447",
                                backgroundColor: "#f3e8ff",
                              },
                            }}
                          >
                            Cancel
                          </Button>
                          <Button
                            type="submit"
                            variant="contained"
                            sx={{
                              backgroundColor: "#1B2447",
                              "&:hover": {
                                backgroundColor: "#6e167d",
                              },
                            }}
                          >
                            {loading ? "Updating..." : "Update"}
                          </Button>
                        </Box>
                      )}
                    </Form>
                  </Formik>
                </Box>
              </Box>
            </motion.div>
          </Modal>
        )}
      </AnimatePresence>
      <CustomSnackbar
        open={snackbar.open}
        message={snackbar.message}
        severity={snackbar.severity}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
      />
    </>
  );
};

export default AddUserModal;
const styles = {
  motionWrapper: {
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    height: "100%",
  },
  container: {
    width: { xs: "92%", md: "80%" },
    maxWidth: 900,
    maxHeight: "90vh",
    bgcolor: "#fff",
    borderRadius: 4,
    p: 4,
    overflowY: "auto",
  },
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    mb: 3,
    p: 2.5,
    borderRadius: 2,
    background: `linear-gradient(135deg, ${PurpleThemeColor}, #a855f7)`,
    color: "#fff",
  },
  title: {
    fontWeight: 700,
    fontSize: "1.25rem",
  },
  closeBtn: {
    color: "#fff",
  },
  formGrid: {
    display: "grid",
    gridTemplateColumns: "1fr 1fr",
    gap: 3,
    mb: 3,
  },
  actions: {
    display: "flex",
    justifyContent: "flex-end",
    gap: 2,
    mt: 3,
  },
};
