import { v2 as cloudinary } from 'cloudinary';

// Configure Cloudinary with environment variables
// Cloud name: dhmdqtrqd (set via CLOUDINARY_CLOUD_NAME)
// API Key & Secret: set via CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dhmdqtrqd',
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

/**
 * Upload a file buffer or local path to Cloudinary.
 *
 * @param {string} filePath  – Local path to the file (multer tmp file)
 * @param {object} options   – Cloudinary upload options
 * @returns {Promise<object>} Cloudinary upload result
 */
export const uploadToCloudinary = (filePath, options = {}) => {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload(
      filePath,
      {
        upload_preset: 'procurax',   // matches your Cloudinary unsigned preset
        ...options,
      },
      (error, result) => {
        if (error) return reject(error);
        resolve(result);
      }
    );
  });
};

/**
 * Delete a file from Cloudinary by its public_id.
 *
 * @param {string} publicId      – The public ID of the asset
 * @param {string} resourceType  – 'image' | 'video' | 'raw' (default: 'image')
 * @returns {Promise<object>}
 */
export const deleteFromCloudinary = (publicId, resourceType = 'image') => {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.destroy(
      publicId,
      { resource_type: resourceType },
      (error, result) => {
        if (error) return reject(error);
        resolve(result);
      }
    );
  });
};

export default cloudinary;
