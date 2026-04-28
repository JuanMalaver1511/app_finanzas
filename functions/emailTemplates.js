function buildKyboEmailTemplate({
  preheader = "Nuevo mensaje de KYBO",
  title,
  message,
  buttonText = "Abrir KYBO",
  buttonUrl = "",
  userName = "",
  badge = "Mensaje importante",
}) {
  const greeting = userName ? `Hola ${userName},` : "Hola,";

  return `
  <div style="margin:0;padding:0;background:#F5F6FB;font-family:Arial,Helvetica,sans-serif;color:#1F2937;">
    <div style="display:none;font-size:1px;color:#F5F6FB;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">
      ${preheader}
    </div>

    <table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F6FB;padding:28px 12px;">
      <tr>
        <td align="center">
          <table width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border-radius:26px;overflow:hidden;box-shadow:0 18px 45px rgba(43,34,87,.16);">
            
            <tr>
              <td style="background:#2B2257;padding:34px 28px 30px;text-align:left;">
                <div style="font-size:13px;font-weight:700;letter-spacing:.14em;color:#FFB84E;text-transform:uppercase;">
                  KYBO
                </div>

                <h1 style="margin:12px 0 0;color:#ffffff;font-size:30px;line-height:1.12;font-weight:900;">
                  ${title || ""}
                </h1>

                <div style="margin-top:18px;display:inline-block;background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.20);color:#ffffff;padding:8px 12px;border-radius:999px;font-size:12px;font-weight:700;">
                  ${badge}
                </div>
              </td>
            </tr>

            <tr>
              <td style="padding:30px 28px 8px;">
                <p style="margin:0 0 14px;color:#2B2257;font-size:16px;font-weight:800;">
                  ${greeting}
                </p>

                <div style="margin:0;color:#4B5563;font-size:15px;line-height:1.7;">
                  ${message || ""}
                </div>

                <div style="margin:28px 0 24px;">
                  <a href="${buttonUrl}" target="_blank" rel="noopener noreferrer"
                    style="display:inline-block;background:#FFB84E;color:#2B2257;text-decoration:none;padding:14px 22px;border-radius:14px;font-weight:900;font-size:14px;">
                    ${buttonText}
                    </a>
                </div>

                <div style="background:#F8F7FF;border:1px solid #E7E3FF;border-radius:18px;padding:16px 18px;margin-top:8px;">
                  <p style="margin:0;color:#2B2257;font-size:13px;line-height:1.55;font-weight:700;">
                    Pequeños hábitos financieros crean grandes resultados.
                  </p>
                </div>
              </td>
            </tr>

            <tr>
              <td style="padding:24px 28px 30px;">
                <table width="100%" cellpadding="0" cellspacing="0" style="background:#FAFAFC;border-radius:18px;padding:16px;">
                  <tr>
                    <td style="font-size:12px;color:#6B7280;line-height:1.6;text-align:center;">
                      Este es un mensaje automático de <strong style="color:#2B2257;">KYBO</strong>.<br/>
                      Controla tus finanzas, toma mejores decisiones y avanza con tranquilidad.
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

          </table>

          <p style="margin:18px 0 0;color:#9CA3AF;font-size:11px;text-align:center;">
            © KYBO App · Gestión financiera personal
          </p>
        </td>
      </tr>
    </table>
  </div>
  `;
}

module.exports = {
  buildKyboEmailTemplate,
};
