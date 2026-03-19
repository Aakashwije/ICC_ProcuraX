import nodemailer from "nodemailer";

/**
 * Create a reusable transporter.
 *
 * Set these environment variables in your .env:
 *   SMTP_HOST=smtp.gmail.com
 *   SMTP_PORT=587
 *   SMTP_USER=your-email@gmail.com
 *   SMTP_PASS=your-app-password      ← use a Gmail "App Password"
 *   SMTP_FROM="ProcuraX <your-email@gmail.com>"
 *
 * NOTE: The transporter is created lazily (on first sendMail call) so that
 * dotenv has already populated process.env before the credentials are read.
 * Creating it at module load time can cause "Missing credentials" errors
 * because ES module static imports are evaluated before the module body of
 * the entry-point (app.js) runs — including the `import "./config/env.js"` line.
 */
let _transporter = null;

function getTransporter() {
  if (!_transporter) {
    _transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || "smtp.gmail.com",
      port: Number(process.env.SMTP_PORT) || 587,
      secure: false, // true for 465, false for 587
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }
  return _transporter;
}

/**
 * Send an email.
 * @param {{ to: string, subject: string, html: string }} options
 */
export const sendMail = async ({ to, subject, html }) => {
  const from = process.env.SMTP_FROM || process.env.SMTP_USER;
  return getTransporter().sendMail({ from, to, subject, html });
};

export default getTransporter;
