require('dotenv').config();

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

/// ==============================
/// CONFIGURACIÓN SEGURA
/// ==============================
const emailUser = process.env.EMAIL_USER;
const emailPass = process.env.EMAIL_PASS;

console.log("📌 SMTP USER:", emailUser);
console.log("📌 SMTP PASS:", emailPass ? "OK" : "NO PASS");

if (!emailUser || !emailPass) {
  console.error("❌ Credenciales de correo no configuradas");
}

/// ==============================
/// TRANSPORTER
/// ==============================
const transporter = nodemailer.createTransport({
  host: "smtp.hostinger.com",
  port: 465,
  secure: true,
  auth: {
    user: emailUser,
    pass: emailPass,
  },
});

/// ==============================
/// FUNCIÓN GEN2
/// ==============================
exports.createUserByAdmin = onCall(async (request) => {
  try {
    console.log("🚀 Ejecutando función createUserByAdmin");

    const { name, email, role, isActive } = request.data;

    if (!name || !email) {
      throw new HttpsError(
        "invalid-argument",
        "Nombre y correo son obligatorios"
      );
    }

    console.log("📌 Creando usuario:", email);

    /// 1. AUTH
    const userRecord = await admin.auth().createUser({
      email,
      password: "Temp1234!",
    });

    const uid = userRecord.uid;

    console.log("✅ Usuario creado:", uid);

    /// 2. FIRESTORE
    await admin.firestore().collection("users").doc(uid).set({
      uid,
      name,
      email,
      role,
      isActive,
      failedAttempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
    });

    console.log("✅ Guardado en Firestore");

    /// 3. LINK
    const link = await admin.auth().generatePasswordResetLink(email);

    console.log("🔗 Link generado");

    /// 4. EMAIL
    console.log("📤 Enviando correo...");

    const info = await transporter.sendMail({
      from: `"KYBO App" <${emailUser}>`,
      to: email,
      subject: "Activa tu cuenta en KYBO",
      html: `
        <div style="font-family: Arial;">
          <h2 style="color:#FFB84E;">Bienvenido a KYBO 💸</h2>
          <p>Hola <b>${name}</b>,</p>
          <p>Haz clic para crear tu contraseña:</p>
          <a href="${link}">Crear contraseña</a>
        </div>
      `,
    });

    console.log("📧 Correo enviado:", info.response);

    return {
      success: true,
      message: "Usuario creado correctamente",
    };

  } catch (error) {
    console.error("❌ ERROR COMPLETO:", error);

    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "El correo ya está registrado"
      );
    }

    throw new HttpsError(
      "internal",
      error.message || "Error al crear el usuario"
    );
  }
});