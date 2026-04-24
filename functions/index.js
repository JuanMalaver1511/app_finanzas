require('dotenv').config();

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const functionsV1 = require("firebase-functions/v1");
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

exports.sendDebtReminderEmails = onSchedule(
  {
    schedule: '0 8 * * *',
    timeZone: 'America/Bogota',
  },
  async () => {
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
  }
);

function getBogotaNow() {
  return new Date(
    new Date().toLocaleString('en-US', { timeZone: 'America/Bogota' })
  );
}

function getDayPeriod(hour) {
  if (hour < 12) return 'morning';
  if (hour < 18) return 'afternoon';
  return 'night';
}

function toNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function buildFinanceMessage({ ingresos, gastos, deudas, balance, period }) {
  const intro = period === 'night'
    ? 'Buenas noches'
    : period === 'afternoon'
      ? 'Buenas tardes'
      : 'Buenos dias';

  if (ingresos <= 0 && gastos <= 0 && deudas <= 0) {
    return {
      title: `${intro}, empieza tu control financiero`,
      body:
        'Aun no registras movimientos este mes. Agrega ingresos, gastos o deudas para recibir un analisis real de tus finanzas.',
    };
  }

  const ratio = ingresos > 0 ? gastos / ingresos : 0;
  const ingresosText = ingresos.toLocaleString('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  });
  const gastosText = gastos.toLocaleString('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  });
  const deudasText = deudas.toLocaleString('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  });
  const balanceText = balance.toLocaleString('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  });

  if (balance < 0) {
    return {
      title: `${intro}, vas mal este mes`,
      body:
        `Tu balance va en ${balanceText}. Ingresos: ${ingresosText}, gastos: ${gastosText}, deudas: ${deudasText}. Reduce gastos para recuperar control.`,
    };
  }

  if (ratio >= 0.9 || deudas > ingresos * 0.3) {
    return {
      title: `${intro}, vas ajustado`,
      body:
        `Tu balance sigue positivo en ${balanceText}, pero ya llevas gastos por ${gastosText} y deudas por ${deudasText}. Revisa en que puedes recortar.`,
    };
  }

  return {
    title: `${intro}, vas bien con tus finanzas`,
    body:
      `Tu balance va positivo en ${balanceText}. Ingresos: ${ingresosText}, gastos: ${gastosText}, deudas: ${deudasText}. Sigue manteniendo ese ritmo.`,
  };
}

async function getUserFinanceSummary(uid) {
  const now = getBogotaNow();
  const year = now.getFullYear();
  const month = now.getMonth();

  const transactionsSnapshot = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('transactions')
    .get();

  let ingresos = 0;
  let gastos = 0;

  for (const doc of transactionsSnapshot.docs) {
    const data = doc.data();
    const amount = toNumber(data.amount);
    const isIncome = data.isIncome === true;
    const date = data.date?.toDate ? data.date.toDate() : null;

    if (!date) continue;
    if (date.getFullYear() !== year || date.getMonth() !== month) continue;

    if (isIncome) {
      ingresos += amount;
    } else {
      gastos += amount;
    }
  }

  const debtsSnapshot = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('debts')
    .get();

  let deudas = 0;

  for (const doc of debtsSnapshot.docs) {
    const data = doc.data();
    const saldoActual = toNumber(data.saldo_actual);
    if (saldoActual <= 0) continue;
    deudas += toNumber(data.cuota_mensual);
  }

  return {
    ingresos,
    gastos,
    deudas,
    balance: ingresos - gastos,
  };
}

async function createInAppNotification(uid, title, body) {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('notifications')
    .add({
      title,
      message: body,
      type: 'admin_message',
      priority: 'medium',
      source: 'finance_scheduler',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    });
}

async function sendFinanceNotificationsToUsers(period = 'manual') {
  const resolvedPeriod =
    period === 'manual' ? getDayPeriod(getBogotaNow().getHours()) : period;
  const usersSnapshot = await admin.firestore().collection('users').get();

  let processedUsers = 0;
  let sentCount = 0;
  let savedNotifications = 0;

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data() || {};
    const role = userData.role || 'user';
    const isBlocked = userData.isBlocked === true || userData.isActive === false;

    if (role === 'admin' || isBlocked) {
      continue;
    }

    processedUsers += 1;

    const uid = userDoc.id;
    const finance = await getUserFinanceSummary(uid);
    const message = buildFinanceMessage({
      ...finance,
      period: resolvedPeriod,
    });

    await createInAppNotification(uid, message.title, message.body);
    savedNotifications += 1;

    const tokens = Array.isArray(userData.notificationTokens)
      ? userData.notificationTokens.filter((token) => typeof token === 'string' && token)
      : [];

    if (!tokens.length) {
      continue;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: message.title,
        body: message.body,
      },
      data: {
        type: 'admin_message',
        title: message.title,
        body: message.body,
        screen: 'notifications',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'kybo_general',
        },
      },
    });

    sentCount += response.successCount;

    const invalidTokens = [];

    response.responses.forEach((result, index) => {
      if (result.success) return;

      const code = result.error?.code || '';
      if (
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/registration-token-not-registered'
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length) {
      await userDoc.ref.update({
        notificationTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
  }

  return {
    success: true,
    processedUsers,
    sentCount,
    savedNotifications,
    period: resolvedPeriod,
  };
}

exports.sendFinanceNotificationsToAllUsers = functionsV1.https.onCall(
  async (data, context) => {
    if (!context.auth?.uid) {
      throw new functionsV1.https.HttpsError(
        'unauthenticated',
        'Debes iniciar sesion.'
      );
    }

    const callerDoc = await admin
      .firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    if (!callerDoc.exists || callerDoc.data()?.role !== 'admin') {
      throw new functionsV1.https.HttpsError(
        'permission-denied',
        'Solo admin puede enviar notificaciones.'
      );
    }

    return await sendFinanceNotificationsToUsers('manual');
  }
);

exports.sendScheduledFinanceNotifications = onSchedule(
  {
    schedule: '0 8,21 * * *',
    timeZone: 'America/Bogota',
  },
  async () => {
    const period = getDayPeriod(getBogotaNow().getHours());
    return await sendFinanceNotificationsToUsers(period);
  }
);
