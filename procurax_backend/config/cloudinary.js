import { v2 as cloudinary } from 'cloudinary';

/**
 * Ensure Cloudinary is configured before each call.
 * Uses hardcoded fallbacks so it works even if env vars
 * are not loaded yet (ESM import ordering).
 */
const ensureConfigured = () => {
  const cloud_name = process.env.CLOUDINARY_CLOUD_NAME || 'dhmdqtrqd';
  const api_key   = process.env.CLOUDINARY_API_KEY     || '488429724665614';
  const api_secret = process.env.CLOUDINARY_API_SECRET  || 'wnLWJMIeD-Q9OLiehdvr4GgHjHA';

  cloudinary.config({ cloud_name, api_key, api_secret, secure: true });
};

/**
 * Sanitize a string for use in Cloudinary public_id or folder.
 * Removes invalid characters and replaces spaces/special chars with underscores.
 *
 * @param {string} str - The string to sanitize
 * @param {boolean} allowDots - Whether to allow dots (for file extensions)
 * @returns {string} Sanitized string
 */
const sanitizeForCloudinary = (str, allowDots = false) => {
  if (!str) return 'file';
  let sanitized = str.trim();
  // Remove extension if present (will be preserved by Cloudinary)
  if (allowDots) {
    const dotIdx = sanitized.lastIndexOf('.');
    const ext = dotIdx > 0 ? sanitized.slice(dotIdx) : '';
    const name = dotIdx > 0 ? sanitized.slice(0, dotIdx) : sanitized;
    // Replace invalid chars in name (anything except word chars, hyphens, underscores)
    const safeName = name.replace(/[^\w-]/g, '_');
    return safeName + ext;
  } else {
    // For folder names, remove dots and slashes entirely
    return sanitized.replace(/[^\w-]/g, '_');
  }
};

/**
 * Upload a file buffer or local path to Cloudinary.
 *
 * @param {string} filePath  – Local path or data URI (base64 data)
 * @param {object} options   – Upload options { resource_type, folder, public_id, ... }
 * @returns {Promise<object>} Cloudinary upload result with secure_url and public_id
 */
export const uploadToCloudinary = (filePath, options = {}) => {
  ensureConfigured();
  
  // Extract folder and public_id from options, sanitize them separately
  const { folder, public_id, ...restOptions } = options;

  // Sanitize public_id: must NEVER contain slashes
  let safePublicId = undefined;
  if (public_id) {
    safePublicId = String(public_id).replaceAll(/[/\\]/g, '_').replaceAll(/[^\w._-]/g, '_');
  }

  // Sanitize folder: slashes ARE allowed (they create nested folders),
  // but each segment must be clean
  let safeFolder = 'procurax';
  if (folder) {
    safeFolder = String(folder)
      .split('/')
      .map(seg => seg.replaceAll(/[^\w._-]/g, '_'))
      .filter(Boolean)
      .join('/');
  }

  const uploadOptions = {
    folder: safeFolder,
    ...(safePublicId && { public_id: safePublicId }),
    ...restOptions,                 // resource_type, etc. (no folder / public_id)
  };

  console.log('[CLOUDINARY] uploading with options:', JSON.stringify(uploadOptions));

  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload(
      filePath,
      uploadOptions,
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
  ensureConfigured();
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
