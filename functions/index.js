require('dotenv').config();

const functions = require("firebase-functions");
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

exports.sendDebtReminderEmails = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('America/Bogota')
  .onRun(async (context) => {
    console.log('🚀 Ejecutando recordatorio de deudas');

    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(now.getDate() + 1);
    const dueDay = tomorrow.getDate();

    const debtsSnapshot = await admin
      .firestore()
      .collectionGroup('debts')
      .where('dia_pago', '==', dueDay)
      .get();

    const users = new Map();

    for (const doc of debtsSnapshot.docs) {
      const data = doc.data();
      const saldoActual = Number(data.saldo_actual) || 0;
      if (saldoActual <= 0) continue;

      const cuotaMensual = Number(data.cuota_mensual) || 0;
      const nombreDeuda = data.nombre || 'Deuda';
      const diaPago = data.dia_pago || dueDay;

      const deudaInfo = {
        nombre: nombreDeuda,
        cuota: cuotaMensual,
        saldo: saldoActual,
        diaPago,
      };

      const userDocRef = doc.ref.parent.parent;
      if (!userDocRef) continue;

      const uid = userDocRef.id;
      const current = users.get(uid) || [];
      current.push(deudaInfo);
      users.set(uid, current);
    }

    let sentCount = 0;

    for (const [uid, debts] of users.entries()) {
      const userRef = admin.firestore().collection('users').doc(uid);
      const userDoc = await userRef.get();

      if (!userDoc.exists) continue;
      const userData = userDoc.data();
      const email = userData?.email;
      const name = userData?.name || 'Usuario';

      if (!email) continue;

      const subject = 'Recordatorio: Mañana vence tu cuota de deuda';
      const header = `Hola ${name},`; 
      const bodyIntro =
        'Tus próximas cuotas vencen mañana. Ponte al día para evitar retrasos e intereses.';
      const debtRows = debts
        .map((debt) =>
          `<li><strong>${debt.nombre}</strong>: cuota ${debt.cuota.toLocaleString('es-CO', { style: 'currency', currency: 'COP' })}, saldo ${debt.saldo.toLocaleString('es-CO', { style: 'currency', currency: 'COP' })}</li>`
        )
        .join('');

      const html = `
        <div style="font-family: Arial, sans-serif; color: #333;">
          <h2 style="color:#FFB84E;">Recordatorio de pago</h2>
          <p>${header}</p>
          <p>${bodyIntro}</p>
          <p><strong>Vencimiento:</strong> mañana, día ${dueDay}</p>
          <ul>${debtRows}</ul>
          <p style="margin-top: 12px;">Con cada pago mantendrás tu saldo bajo control y te liberarás de deudas más rápido.</p>
          <p>Revisa tu app para registrar tu pago.</p>
        </div>
      `;

      try {
        const info = await transporter.sendMail({
          from: `"KYBO App" <${emailUser}>`,
          to: email,
          subject,
          html,
        });
        console.log(`📧 Correo recordatorio enviado a ${email}:`, info.response);
        sentCount += 1;
      } catch (error) {
        console.error(`❌ Error enviando recordatorio a ${email}:`, error);
      }
    }

    return {
      success: true,
      dueDay,
      reminders: sentCount,
    };
  });