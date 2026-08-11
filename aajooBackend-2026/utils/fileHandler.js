const multer = require("multer");
const fs = require("fs");
const path = require("path");

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const folderName = file.fieldname;
        const dir = path.join("uploads", folderName);

        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }

        cb(null, dir);
    },

    filename: (req, file, cb) => {
        const currentDate = new Date().toISOString().split("T")[0];
        const sanitizedName = file.originalname
            .replace(/\s+/g, "_")
            .replace(/[^a-zA-Z0-9._-]/g, "");

        cb(null, `${currentDate}-${Date.now()}-${sanitizedName}`);
    },
});

// ✅ IMAGES ONLY (NO SIZE LIMIT)
const imageOnlyFilter = (req, file, cb) => {
    // Check MIME type
    if (file.mimetype.startsWith("image/")) {
        cb(null, true);
        return;
    }

    // Fallback: Check file extension for common image formats
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    const fileExtension = path.extname(file.originalname).toLowerCase();
    
    if (allowedExtensions.includes(fileExtension)) {
        cb(null, true);
    } else {
        cb(new Error("Only image files are allowed"), false);
    }
};

exports.upload = multer({
    storage,
    fileFilter: imageOnlyFilter,
    // ❌ no limits added (as requested)
});
