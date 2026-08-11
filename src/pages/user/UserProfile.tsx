import React, { useEffect, useRef, useState } from "react";
import {
  Box,
  Button,
  Paper,
  Avatar,
  TextField,
  Typography,
  MenuItem,
  IconButton,
  InputAdornment,
  CircularProgress,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { Visibility, VisibilityOff } from "@mui/icons-material";
import toast from "react-hot-toast";
import { useNavigate } from "react-router-dom";
import userImg from "../../assets/UI/userDemo.jpg";
import storage from "../../styles/utils/storage";
import { getUserDetail, updateUser } from "../../services/customerApi";
import ThemedDatePicker from "../../components/frontend/ThemedDatePicker";
import "../../styles/user/UserProfile.css";

interface ProfileForm {
  user_fullName: string;
  user_email: string; // read-only (credential)
  user_dob: string; // read-only display
  user_gender: string;
  user_address: string;
  user_pnumber: string;
  user_country: string;
  user_city: string;
  user_zipcode: string;
}

const emptyForm: ProfileForm = {
  user_fullName: "",
  user_email: "",
  user_dob: "",
  user_gender: "",
  user_address: "",
  user_pnumber: "",
  user_country: "",
  user_city: "",
  user_zipcode: "",
};

const UserProfile: React.FC = () => {
  const navigate = useNavigate();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [preview, setPreview] = useState(userImg);
  const [image, setImage] = useState<string | null>(null);

  const [showOldPassword, setShowOldPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);

  const [form, setForm] = useState<ProfileForm>(emptyForm);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // Prefill from GET /user/detail
  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const user = await getUserDetail();
        if (cancelled || !user) return;
        setForm({
          user_fullName: user.user_fullName ?? "",
          user_email: user.cred_user_email ?? user.user_email ?? "",
          user_dob: user.user_dob ?? "",
          user_gender: user.user_gender ?? "",
          user_address: user.user_address ?? "",
          user_pnumber: user.user_pnumber ?? "",
          user_country: user.user_country ?? "",
          user_city: user.user_city ?? "",
          user_zipcode: user.user_zipcode ?? "",
        });
        if (user.attachment) setPreview(user.attachment);
      } catch {
        // keep empty form; submit still works for a fresh profile
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const handleToggleOldPassword = () => setShowOldPassword((prev) => !prev);
  const handleToggleNewPassword = () => setShowNewPassword((prev) => !prev);

  const handleField =
    (key: keyof ProfileForm) =>
    (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      setForm((prev) => ({ ...prev, [key]: e.target.value }));

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setPreview(URL.createObjectURL(e.target.files[0]));
    }
  };
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setImage(URL.createObjectURL(e.target.files[0]));
    }
  };

  const handleRemoveImage = () => {
    setImage(null);
  };

  const handleUploadClick = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleLogout = () => {
    storage.clearToken();
    toast.success("Logged out");
    navigate("/");
  };

  // Submit only the fields the backend persists (POST /user/update).
  const handleSubmit = async () => {
    if (!form.user_fullName.trim()) {
      toast.error("Full name is required");
      return;
    }
    setSaving(true);
    try {
      await updateUser({
        user_fullName: form.user_fullName,
        user_pnumber: form.user_pnumber,
        user_address: form.user_address,
        user_city: form.user_city,
        user_zipcode: form.user_zipcode,
      });
      toast.success("Profile updated successfully");
    } catch (e: any) {
      toast.error(
        e?.response?.data?.message ||
          e?.message ||
          "Couldn't update your profile. Please try again."
      );
    } finally {
      setSaving(false);
    }
  };

  const firstName = form.user_fullName.trim().split(" ")[0] || "there";

  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "50vh" }}>
        <CircularProgress sx={{ color: "#1B2447" }} />
      </Box>
    );
  }

  return (
    <Box className="mainContaineruserProfile">
      {/* Left Side Profile Section */}
      <Paper className="leftContaineruserProfile" elevation={2}>
        <Box className="imageContainerUserProfile">
          <Avatar
            src={preview}
            alt="User"
            className="userDemoImg"
            sx={{ width: 120, height: 120 }}
          />
          <input
            type="file"
            accept="image/*"
            ref={fileInputRef}
            onChange={handleFileChange}
            style={{ display: "none" }}
          />
          <Button
            variant="contained"
            sx={{
              backgroundColor: "#1B2447",
              "&:hover": { backgroundColor: "#2A356B" },
            }}
            onClick={handleUploadClick}
          >
            Change Photo
          </Button>
        </Box>

        {/* Change Password Section */}
        <Box
          className="changePasswordContainer"
          sx={{ maxWidth: 400, mx: "auto", mt: 4 }}
        >
          <Typography
            variant="h6"
            className="changePasswordTitle"
            sx={{ fontWeight: 700, mb: 2, fontFamily: "'Inter', sans-serif" }}
          >
            Change Password
          </Typography>

          {/* Old Password */}
          <TextField
            label="Old Password"
            type={showOldPassword ? "text" : "password"}
            variant="outlined"
            fullWidth
            margin="normal"
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton onClick={handleToggleOldPassword} edge="end">
                    {showOldPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          {/* New Password */}
          <TextField
            label="New Password"
            type={showNewPassword ? "text" : "password"}
            variant="outlined"
            fullWidth
            margin="normal"
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton onClick={handleToggleNewPassword} edge="end">
                    {showNewPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          {/* Buttons */}
          <Button
            variant="contained"
            fullWidth
            sx={{
              mt: 2,
              backgroundColor: "#1B2447",
              "&:hover": { backgroundColor: "#2A356B" },
            }}
          >
            Change Password
          </Button>

          <Button
            variant="contained"
            fullWidth
            sx={{
              mt: 2,
              backgroundColor: "#1B2447",
              "&:hover": { backgroundColor: "#2A356B" },
            }}
          >
            Delete Account
          </Button>

          <Button
            variant="contained"
            fullWidth
            onClick={handleLogout}
            sx={{
              mt: 2,
              backgroundColor: "#1B2447",
              "&:hover": { backgroundColor: "#2A356B" },
            }}
          >
            Logout
          </Button>
        </Box>
      </Paper>

      {/* Right Side Section */}
      <Box className="rightContaineruserProfile">
        {/* ⭐ Welcome Header with User Name */}
        <Box
          sx={{
            mb: 3,
            p: 2,
            borderRadius: "12px",
            background: "#FFFAF0",
            border: "1px solid #D9CFB8",
            textAlign: "center",
          }}
        >
          <Typography
            sx={{
              fontSize: "1.4rem",
              fontWeight: 700,
              fontFamily: "'Fraunces', serif",
              color: "#1B2447",
              mb: 0.5,
            }}
          >
            Welcome Back,{" "}
            <span style={{ color: "#C16345", fontStyle: "italic" }}>
              {firstName}!
            </span>
          </Typography>

          <Typography
            sx={{
              fontSize: "0.95rem",
              fontWeight: 500,
              color: "#6b6b6b",
              fontFamily: "'Inter', sans-serif",
            }}
          >
            Manage your personal information and account settings
          </Typography>
        </Box>
        <Typography variant="h4" className="userInforight">
          User Information
        </Typography>
        <Box className="userInfoFormProfile">
          {/* Full Name + Email */}
          <Box className="inputsUserinfoProfile">
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">Email</Typography>
              <TextField
                type="email"
                variant="outlined"
                fullWidth
                label="Email"
                margin="normal"
                value={form.user_email}
                InputProps={{ readOnly: true }}
                helperText="Email can't be changed here"
              />
            </Box>
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">
                Full Name
              </Typography>
              <TextField
                type="text"
                label="Full Name"
                variant="outlined"
                fullWidth
                margin="normal"
                value={form.user_fullName}
                onChange={handleField("user_fullName")}
              />
            </Box>
          </Box>

          {/* DOB + Gender */}
          <Box className="inputsUserinfoProfile">
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">DOB</Typography>
              <Box sx={{ mt: 2 }}>
                <ThemedDatePicker
                  label="Date of Birth"
                  value={form.user_dob}
                  onChange={(v) => setForm((prev) => ({ ...prev, user_dob: v }))}
                  disableFuture
                />
              </Box>
            </Box>
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">Gender</Typography>
              <TextField
                select
                variant="outlined"
                fullWidth
                margin="normal"
                label="Gender"
                value={form.user_gender}
                onChange={handleField("user_gender")}
              >
                <MenuItem value="male">Male</MenuItem>
                <MenuItem value="female">Female</MenuItem>
                <MenuItem value="other">Other</MenuItem>
              </TextField>
            </Box>
          </Box>

          {/* Address */}
          <Box className="inputsUserinfoProfile">
            <Box className="inputboxChilduserProfile" style={{ width: "100%" }}>
              <Typography className="userProfileFormLabel">Address</Typography>
              <TextField
                variant="outlined"
                fullWidth
                label="Full Address"
                margin="normal"
                multiline
                rows={3}
                value={form.user_address}
                onChange={handleField("user_address")}
              />
            </Box>
          </Box>

          {/* Contact Number + Country */}
          <Box className="inputsUserinfoProfile">
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">
                Contact Number
              </Typography>
              <TextField
                type="tel"
                label="Contact Number"
                variant="outlined"
                fullWidth
                margin="normal"
                value={form.user_pnumber}
                onChange={handleField("user_pnumber")}
              />
            </Box>
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">Country</Typography>
              <TextField
                type="text"
                variant="outlined"
                label="Country"
                fullWidth
                margin="normal"
                value={form.user_country}
                onChange={handleField("user_country")}
              />
            </Box>
          </Box>

          {/* City + Pincode */}
          <Box className="inputsUserinfoProfile">
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">City</Typography>
              <TextField
                type="text"
                variant="outlined"
                label="City"
                fullWidth
                margin="normal"
                value={form.user_city}
                onChange={handleField("user_city")}
              />
            </Box>
            <Box className="inputboxChilduserProfile">
              <Typography className="userProfileFormLabel">Pincode</Typography>
              <TextField
                type="text"
                variant="outlined"
                label="Pincode"
                fullWidth
                margin="normal"
                value={form.user_zipcode}
                onChange={handleField("user_zipcode")}
              />
            </Box>
          </Box>

          {/* Upload ID */}
          <Box className="inputsUserinfoProfile uploadSection">
            <Box className="inputboxChilduserProfile" style={{ width: "100%" }}>
              <Typography className="userProfileFormLabel">
                Upload ID
              </Typography>
              <Box className="uploadBox">
                <Button
                  variant="contained"
                  component="label"
                  className="chooseFileBtn"
                >
                  Choose File
                  <input
                    hidden
                    type="file"
                    accept="image/*"
                    onChange={handleImageChange}
                  />
                </Button>
                {image && (
                  <Box className="imagePreview">
                    <img src={image} alt="Preview" className="previewImg" />
                    <IconButton
                      className="removeImgBtn"
                      onClick={handleRemoveImage}
                    >
                      <CloseIcon />
                    </IconButton>
                  </Box>
                )}
              </Box>
            </Box>
          </Box>

          {/* Submit Button */}
          <Box
            className="inputsUserinfoProfile"
            style={{ justifyContent: "center" }}
          >
            <Button
              variant="contained"
              color="primary"
              className="submitBtn"
              onClick={handleSubmit}
              disabled={saving}
              startIcon={saving ? <CircularProgress size={18} sx={{ color: "#fff" }} /> : undefined}
            >
              {saving ? "Saving…" : "Submit"}
            </Button>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default UserProfile;
