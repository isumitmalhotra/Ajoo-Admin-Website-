import { Button } from "@mui/material";
import "./propertyModal.css";
import { useState } from "react";
import { Camera } from "lucide-react";

type PropertyModalProps = {
  open: boolean;
  onClose: () => void;
};

const PropertyModal = ({ open, onClose }: PropertyModalProps) => {
  const [selectedImages, setSelectedImages] = useState<File[]>([]);

  if (!open) return null;

  const handleBackdropClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files ? Array.from(e.target.files) : [];
    setSelectedImages(files);
  };

  return (
    <div className="propertyModalBackdrop" onClick={handleBackdropClick}>
      <section
        className="propertyModalSection"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="propertyModalHeader">
          <h2>Property Details</h2>
          <button className="closeButton" onClick={onClose}>
            ×
          </button>
        </div>

        <div className="propertyModalContent">
          <form className="propertyForm">
            <div className="formGrid">
              {/* Existing inputs */}
              <div className="inputGroup">
                <label>Full Name</label>
                <input
                  type="text"
                  name="name"
                  placeholder="Enter full name"
                  required
                />
              </div>

              <div className="inputGroup">
                <label>Email Address</label>
                <input
                  type="email"
                  name="email"
                  placeholder="Enter email address"
                  required
                />
              </div>

              <div className="inputGroup">
                <label>Age</label>
                <input
                  type="number"
                  name="age"
                  min="0"
                  placeholder="Enter age"
                  required
                />
              </div>

              <div className="inputGroup">
                <label>Date of Birth</label>
                <input type="date" name="dob" required />
              </div>

              <div className="inputGroup">
                <label>User Status</label>
                <select name="userStatus" required>
                  <option value="">Select Status</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>

              <div className="inputGroup">
                <label>Verification Status</label>
                <div className="radioGroup">
                  <label className="radioLabel">
                    <input type="radio" name="isVerified" value="true" />
                    <span>Verified</span>
                  </label>
                  <label className="radioLabel">
                    <input type="radio" name="isVerified" value="false" />
                    <span>Not Verified</span>
                  </label>
                </div>
              </div>
            </div>

            <div>
              <label>Address</label>
              <textarea
                name="address"
                placeholder="Enter address"
                rows={4}
                required
                className="addressTextarea"
              ></textarea>
            </div>

            <div className="inputGroupFileUpload">
              <label htmlFor="imageUpload" className="customUploadArea">
                <span className="uploadIcon"><Camera/></span>
                <span className="uploadText">Upload</span>
              </label>
              <input
                type="file"
                id="imageUpload"
                name="images"
                accept="image/*"
                multiple
                onChange={handleImageChange}
                className="imageUploadInput"
                required
              />
            </div>

            <div className="imagePreviewBox">
              {selectedImages.map((image, index) => (
                <img
                  key={index}
                  src={URL.createObjectURL(image)}
                  alt={`preview-${index}`}
                  className="previewImage"
                />
              ))}
            </div>
          </form>
        </div>

        <div className="propertyModalFooter">
          <Button
            variant="outlined"
            onClick={onClose}
            size="large"
            sx={{
              color: "#d32f2f",
              borderColor: "#d32f2f",
              textTransform: "Capitalize",
              fontFamily: "Lato, sans-serif",
              "&:hover": {
                borderColor: "#b71c1c",
                backgroundColor: "#ffebee",
              },
            }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            size="large"
            sx={{
              backgroundColor: "#3D4670",
              fontFamily: "Lato, sans-serif",
              textTransform: "Capitalize",
              color: "#fff",
            }}
          >
            Save Changes
          </Button>
        </div>
      </section>
    </div>
  );
};

export default PropertyModal;
