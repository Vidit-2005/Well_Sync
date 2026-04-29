// supabase/functions/send-patient-welcome/index.ts
//
// Supabase Edge Function — sends a welcome e-mail to a newly registered
// patient using Gmail SMTP via nodemailer (npm specifier, Deno-native).
//
// ── Required Supabase Secrets ──────────────────────────────────────────
//   GMAIL_USER     : your Gmail address      e.g. wellsync@gmail.com
//   GMAIL_APP_PASS : 16-char Gmail App Password (NOT your account password)
//
// ── Deploy ─────────────────────────────────────────────────────────────
//   supabase functions deploy send-patient-welcome --no-verify-jwt

import nodemailer from "npm:nodemailer@6.9.7";

// ── CORS headers ────────────────────────────────────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── Entry point — Deno.serve() is built-in, no import needed ───────────
Deno.serve(async (req: Request) => {

  // Handle pre-flight CORS requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Parse request body ──────────────────────────────────────────
    const { patientEmail, patientName, password, doctorName } =
      await req.json() as {
        patientEmail: string;
        patientName:  string;
        password:     string;
        doctorName:   string;
      };

    if (!patientEmail || !patientName || !password || !doctorName) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── 2. Read Gmail credentials from Supabase secrets ───────────────
    const gmailUser = Deno.env.get("GMAIL_USER");
    const gmailPass = Deno.env.get("GMAIL_APP_PASS");

    if (!gmailUser || !gmailPass) {
      console.error("GMAIL_USER or GMAIL_APP_PASS secret is not set");
      return new Response(
        JSON.stringify({ error: "Email service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── 3. Build email content ─────────────────────────────────────────
    const htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to WellSync</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
           background: #f5f5f7; margin: 0; padding: 0; }
    .container { max-width: 560px; margin: 40px auto; background: #ffffff;
                 border-radius: 16px; overflow: hidden;
                 box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #4F8EF7 0%, #6B5BFC 100%);
              padding: 36px 32px; text-align: center; }
    .header h1 { color: #fff; font-size: 28px; font-weight: 700; margin: 0; letter-spacing: -0.5px; }
    .header p  { color: rgba(255,255,255,0.85); font-size: 15px; margin: 8px 0 0; }
    .body { padding: 32px; }
    .greeting { font-size: 17px; color: #1c1c1e; margin-bottom: 20px; }
    .credentials { background: #f2f2f7; border-radius: 12px; padding: 20px 24px; margin: 24px 0; }
    .credentials h2 { font-size: 13px; font-weight: 600; color: #6e6e73;
                      text-transform: uppercase; letter-spacing: 0.8px; margin: 0 0 14px; }
    .cred-row { display: flex; align-items: center; margin-bottom: 10px; }
    .cred-row:last-child { margin-bottom: 0; }
    .cred-label { font-size: 14px; color: #6e6e73; width: 90px; flex-shrink: 0; }
    .cred-value { font-size: 16px; font-weight: 600; color: #1c1c1e;
                  font-family: 'SF Mono', 'Menlo', monospace; }
    .notice { background: #fff3cd; border-left: 4px solid #f0ad4e;
              border-radius: 8px; padding: 14px 16px; font-size: 14px; color: #856404;
              margin-bottom: 24px; line-height: 1.5; }
    .footer { border-top: 1px solid #e5e5ea; padding: 20px 32px;
              font-size: 13px; color: #8e8e93; text-align: center; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🌿 WellSync</h1>
      <p>Your personalised health companion</p>
    </div>
    <div class="body">
      <p class="greeting">Hello <strong>${patientName}</strong>,</p>
      <p style="font-size:15px;color:#3a3a3c;line-height:1.6;">
        <strong>Dr. ${doctorName}</strong> has registered you on <strong>WellSync</strong> —
        a health management app designed to keep you and your doctor connected.
        Below are your login credentials. Please keep them safe.
      </p>
      <div class="credentials">
        <h2>Your Login Details</h2>
        <div class="cred-row">
          <span class="cred-label">📧 Email</span>
          <span class="cred-value">${patientEmail}</span>
        </div>
        <div class="cred-row">
          <span class="cred-label">🔑 Password</span>
          <span class="cred-value">${password}</span>
        </div>
      </div>
      <div class="notice">
        ⚠️ <strong>Security tip:</strong> We recommend changing your password
        after your first login. Go to <em>Settings → Change Password</em> inside the app.
      </div>
      <p style="font-size:15px;color:#3a3a3c;line-height:1.6;">
        Download the WellSync app on your iPhone and sign in with the
        credentials above to get started.
      </p>
    </div>
    <div class="footer">
      This email was sent by WellSync on behalf of Dr. ${doctorName}.<br>
      If you did not expect this email, please contact your doctor's clinic.
    </div>
  </div>
</body>
</html>`;

    const textBody = `
Welcome to WellSync!

Hello ${patientName},

Dr. ${doctorName} has registered you on WellSync, your personalised health companion.

Your login credentials:
  Email:    ${patientEmail}
  Password: ${password}

Please change your password after first login via Settings → Change Password.

If you did not expect this email, please contact your doctor's clinic.
— The WellSync Team`.trim();

    // ── 4. Create Gmail SMTP transporter via nodemailer ───────────────
    const transporter = nodemailer.createTransport({
      host:   "smtp.gmail.com",
      port:   465,
      secure: true,           // SSL on port 465
      auth: {
        user: gmailUser,
        pass: gmailPass,      // Gmail App Password
      },
    });

    // ── 5. Send the email ─────────────────────────────────────────────
    await transporter.sendMail({
      from:    `"WellSync" <${gmailUser}>`,
      to:      patientEmail,
      subject: "Welcome to WellSync — Your Login Details",
      text:    textBody,
      html:    htmlBody,
    });

    console.log(`✅ Welcome email sent to ${patientEmail}`);

    return new Response(
      JSON.stringify({ success: true, message: `Email sent to ${patientEmail}` }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("Edge function error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
