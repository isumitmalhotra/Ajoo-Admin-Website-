const multer = require("multer");
const fs = require("fs");
const path = require("path");

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // console.log(file, "file in storage destination");
        const folderName = file.fieldname; // dynamic folder
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
    if (file.mimetype.startsWith("image/")) {
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
