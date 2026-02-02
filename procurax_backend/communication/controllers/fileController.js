import { bucket } from "../config/firebase.js";
import { v4 as uuidv4 } from "uuid";
import path from "path";

// Upload a file to Firebase Storage
async function uploadFile(req, res) {
  try {
    // Check if file is present
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    const file = req.file;
    // Generate a unique file name
    const fileName = `${uuidv4()}${path.extname(file.originalname)}`;
    const filePath = `uploads/${fileName}`;

    // Create a reference to the file in Firebase Storage
    const blob = bucket.file(filePath);

    // Create a stream to upload the file
    const blobStream = blob.createWriteStream({
      metadata: {
        contentType: file.mimetype, // Set the content type
      },
    });

    // Handle upload errors
    blobStream.on("error", (err) => {
      console.error("Upload error:", err);
      res.status(500).json({ error: "Upload failed" });
    });

    // Handle successful upload
    blobStream.on("finish", async () => {
      // Make file public (simple approach)
      await blob.makePublic();

      //public downlaod URL
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`;
      res.status(201).json({
        fileName: blob.name,
        url: publicUrl,
        originalName: file.originalname,
        mimeType: file.mimetype,
      });
    });

    // Start uploading the file
    blobStream.end(file.buffer);
  } catch (error) {
    console.error("Error uploading file:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

//
async function downloadFile(req, res) {
  try {
    // Get the file name from request parameters
    const fileName = req.params.fileName;
    const file = bucket.file(fileName);

    // Check if file exists
    const [exists] = await file.exists();
    if (!exists) {
      return res.status(404).json({ error: "File not found" });
    }


    // Set headers and stream the file to response
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${path.basename(fileName)}"`
    );

    // stream the file
    file.createReadStream().pipe(res);
  } catch (error) {
    console.error("Error downloading file:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

export {
  uploadFile,
  downloadFile,
};
