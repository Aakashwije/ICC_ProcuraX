import { Resend } from "resend";

/**
 * Email delivery via Resend (HTTPS API — works on all Railway plans).
 *
 * Railway blocks outbound SMTP (port 587) on Free/Hobby plans, so
 * nodemailer + Gmail SMTP hangs and times out. Resend uses a standard
 * HTTPS API call instead, which is never blocked.
 *
 * Required environment variable:
 *   RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxx   ← from https://resend.com/api-keys
 *
 * Optional:
 *   MAIL_FROM="ProcuraX <onboarding@resend.dev>"
 *   (defaults to Resend's shared sandbox address for testing)
 */

let _resend = null;

function getResend() {
  if (!_resend) {
    _resend = new Resend(process.env.RESEND_API_KEY);
  }
  return _resend;
}

/**
 * Send an email.
 * @param {{ to: string, subject: string, html: string }} options
 */
export const sendMail = async ({ to, subject, html }) => {
  const from =
    process.env.MAIL_FROM ||
    "ProcuraX <onboarding@resend.dev>";

  const { data, error } = await getResend().emails.send({
    from,
    to,
    subject,
    html,
  });

  if (error) {
    throw new Error(`Resend error: ${error.message}`);
  }

  return data;
};

export default getResend;
