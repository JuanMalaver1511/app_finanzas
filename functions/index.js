require("dotenv").config();

const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const functionsV1 = require("firebase-functions/v1");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const { buildKyboEmailTemplate } = require("./emailTemplates");
const APP_URL = "https://kyboapp.com";

function buildTrackingUrl({
  campaignId,
  uid,
  targetPath = "/#/notifications",
}) {
  const destination = encodeURIComponent(`${APP_URL}${targetPath}`);

  return `https://trackemailclick-wnfkevrrxa-uc.a.run.app?campaignId=${campaignId}&uid=${uid}&destination=${destination}`;
}

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
/// VALIDAR ADMIN
/// ==============================
async function assertAdmin(uid) {
  if (!uid) {
    throw new functionsV1.https.HttpsError(
      "unauthenticated",
      "Debes iniciar sesión.",
    );
  }

  const callerDoc = await admin.firestore().collection("users").doc(uid).get();

  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new functionsV1.https.HttpsError(
      "permission-denied",
      "Solo admin puede ejecutar esta acción.",
    );
  }
}

async function registerUniqueInteraction({ campaignRef, uid, channel }) {
  if (!uid) return;

  const interactionRef = campaignRef.collection("interactions").doc(uid);
  const interactionDoc = await interactionRef.get();

  const updateData = {
    uid,
    lastInteractionAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (channel === "email") {
    updateData.emailClick = true;
    updateData.lastEmailClickAt = admin.firestore.FieldValue.serverTimestamp();
  }

  if (channel === "app") {
    updateData.appRead = true;
    updateData.lastAppReadAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await interactionRef.set(updateData, { merge: true });

  if (!interactionDoc.exists) {
    await campaignRef.set(
      {
        uniqueInteractionCount: admin.firestore.FieldValue.increment(1),
        lastInteractionAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } else {
    await campaignRef.set(
      {
        lastInteractionAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

exports.trackEmailClick = onRequest(
  {
    region: "us-central1",
    cors: true,
  },
  async (req, res) => {
    try {
      const campaignId = req.query.campaignId?.toString();
      const uid = req.query.uid?.toString();
      const destination =
        req.query.destination?.toString() || `${APP_URL}/#/notifications`;

      if (campaignId) {
        const campaignRef = admin
          .firestore()
          .collection("notification_campaigns")
          .doc(campaignId);

        const clickId = uid || `anonymous_${Date.now()}`;

        const clickRef = campaignRef.collection("email_clicks").doc(clickId);
        const clickDoc = await clickRef.get();

        if (!clickDoc.exists) {
          await campaignRef.set(
            {
              emailClickCount: admin.firestore.FieldValue.increment(1),
              lastEmailClickAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );

          await clickRef.set({
            uid: uid || null,
            firstClickAt: admin.firestore.FieldValue.serverTimestamp(),
            lastClickAt: admin.firestore.FieldValue.serverTimestamp(),
            clickCount: 1,
            userAgent: req.headers["user-agent"] || null,
            ip:
              req.headers["x-forwarded-for"]?.toString().split(",")[0] ||
              req.ip ||
              null,
          });

          await registerUniqueInteraction({
            campaignRef,
            uid,
            channel: "email",
          });
        } else {
          await clickRef.update({
            lastClickAt: admin.firestore.FieldValue.serverTimestamp(),
            clickCount: admin.firestore.FieldValue.increment(1),
          });
        }
      }

      return res.redirect(destination);
    } catch (error) {
      console.error("Error registrando clic de correo:", error);
      return res.redirect(`${APP_URL}/#/notifications`);
    }
  },
);

/// ==============================
/// CREAR USUARIO DESDE ADMIN
/// ==============================
exports.createUserByAdmin = onCall(async (request) => {
  try {
    console.log("🚀 Ejecutando función createUserByAdmin");

    const { name, email, role, isActive } = request.data;

    if (!name || !email) {
      throw new HttpsError(
        "invalid-argument",
        "Nombre y correo son obligatorios",
      );
    }

    console.log("📌 Creando usuario:", email);

    const userRecord = await admin.auth().createUser({
      email,
      password: "Temp1234!",
    });

    const uid = userRecord.uid;

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

    const link = await admin.auth().generatePasswordResetLink(email);

    const info = await transporter.sendMail({
      from: `"KYBO App" <${emailUser}>`,
      to: email,
      subject: "Activa tu cuenta en KYBO",
      html: buildKyboEmailTemplate({
        preheader: "Activa tu cuenta en KYBO",
        title: "Bienvenido a KYBO",
        message: `Tu cuenta fue creada correctamente. Haz clic en el botón para crear tu contraseña y empezar a usar la app.`,
        buttonText: "Crear mi contraseña",
        buttonUrl: link,
        userName: name,
        badge: "Cuenta creada",
      }),
    });

    console.log("📧 Correo enviado:", info.response);

    return {
      success: true,
      message: "Usuario creado correctamente",
    };
  } catch (error) {
    console.error("❌ ERROR COMPLETO:", error);

    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "El correo ya está registrado");
    }

    throw new HttpsError(
      "internal",
      error.message || "Error al crear el usuario",
    );
  }
});

/// ==============================
/// UTILIDADES
/// ==============================
function getBogotaNow() {
  return new Date(
    new Date().toLocaleString("en-US", { timeZone: "America/Bogota" }),
  );
}

function getDayPeriod(hour) {
  if (hour < 12) return "morning";
  if (hour < 18) return "afternoon";
  return "night";
}

function toNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

/// ==============================
/// MENSAJE FINANCIERO AUTOMÁTICO
/// PERO EJECUTADO MANUALMENTE POR ADMIN
/// ==============================
function buildFinanceMessage({ ingresos, gastos, deudas, balance, period }) {
  const intro =
    period === "night"
      ? "Buenas noches"
      : period === "afternoon"
        ? "Buenas tardes"
        : "Buenos días";

  const format = (value) =>
    value.toLocaleString("es-CO", {
      style: "currency",
      currency: "COP",
      maximumFractionDigits: 0,
    });

  if (ingresos <= 0 && gastos <= 0 && deudas <= 0) {
    return {
      title: `${intro}, empieza tu control financiero`,
      body: "Aún no registras movimientos este mes. Agrega tus ingresos y gastos para que KYBO pueda ayudarte con un análisis real.",
      type: "finance_reminder",
      priority: "low",
      sendEmail: false,
    };
  }

  if (balance < 0) {
    return {
      title: "Alerta: balance negativo",
      body: `Tu balance actual es ${format(balance)}. Revisa tus gastos recientes y ajusta tu presupuesto para recuperar estabilidad.`,
      type: "finance_alert",
      priority: "high",
      sendEmail: true,
    };
  }

  if (ingresos > 0 && gastos >= ingresos * 0.9) {
    return {
      title: "Tus gastos están muy cerca de tus ingresos",
      body: `Has registrado gastos por ${format(gastos)} frente a ingresos de ${format(ingresos)}. Es buen momento para revisar en qué puedes recortar.`,
      type: "spending_alert",
      priority: "high",
      sendEmail: true,
    };
  }

  if (ingresos > 0 && deudas >= ingresos * 0.4) {
    return {
      title: "Revisa tus compromisos de deuda",
      body: `Tus cuotas o compromisos de deuda suman aproximadamente ${format(deudas)}. Prioriza pagos y evita afectar tu flujo mensual.`,
      type: "debt_alert",
      priority: "medium",
      sendEmail: true,
    };
  }

  return {
    title: `${intro}, vas bien con tus finanzas`,
    body: `Mantienes un balance positivo de ${format(balance)}. Sigue registrando tus movimientos para conservar el control.`,
    type: "finance_summary",
    priority: "low",
    sendEmail: false,
  };
}

async function getUserFinanceSummary(uid) {
  const now = getBogotaNow();
  const year = now.getFullYear();
  const month = now.getMonth();

  const transactionsSnapshot = await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("transactions")
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
    .collection("users")
    .doc(uid)
    .collection("debts")
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

async function createInAppNotification(uid, title, body, options = {}) {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .add({
      title,
      message: body,
      type: options.type || "admin_message",
      priority: options.priority || "medium",
      source: options.source || "admin_panel",
      campaignId: options.campaignId || null,
      dedupeKey: options.dedupeKey || null,
      isRead: false,
      readTracked: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    });
}

async function createNotificationCampaign({
  title,
  message,
  category,
  campaignType,
  source,
  target = "all",
  sendApp = true,
  sendEmail = false,
  priority = "medium",
  status = "sent",
  scheduledAt = null,
  metadata = {},
}) {
  const campaignRef = await admin
    .firestore()
    .collection("notification_campaigns")
    .add({
      title,
      message,
      category,
      campaignType,
      source,
      target,
      sendApp,
      sendEmail,
      priority,
      status,
      scheduledAt,
      sentAt:
        status === "sent" ? admin.firestore.FieldValue.serverTimestamp() : null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),

      totalRecipients: 0,
      appSent: 0,
      emailSent: 0,
      readCount: 0,
      emailClickCount: 0,
      lastEmailClickAt: null,
      uniqueInteractionCount: 0,
      lastInteractionAt: null,

      ...metadata,
    });

  return campaignRef;
}

async function sendPushNotificationToUser(userData, title, body) {
  const tokens = Array.isArray(userData.notificationTokens)
    ? userData.notificationTokens.filter(
        (token) => typeof token === "string" && token,
      )
    : [];

  if (!tokens.length) {
    return {
      successCount: 0,
      invalidTokens: [],
    };
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title,
      body,
    },
    data: {
      type: "admin_message",
      title,
      body,
      screen: "notifications",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "kybo_general",
      },
    },
  });

  const invalidTokens = [];

  response.responses.forEach((result, index) => {
    if (result.success) return;

    const code = result.error?.code || "";

    if (
      code === "messaging/invalid-registration-token" ||
      code === "messaging/registration-token-not-registered"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  return {
    successCount: response.successCount,
    invalidTokens,
  };
}

/// ==============================
/// ENVIAR ANÁLISIS FINANCIERO MANUAL
/// SOLO DESDE PANEL ADMIN
/// ==============================
async function sendFinanceNotificationsToUsers(period = "manual") {
  const resolvedPeriod =
    period === "manual" ? getDayPeriod(getBogotaNow().getHours()) : period;

  const usersSnapshot = await admin.firestore().collection("users").get();

  let processedUsers = 0;
  let sentCount = 0;
  let savedNotifications = 0;

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data() || {};
    const role = userData.role || "user";
    const isBlocked =
      userData.isBlocked === true || userData.isActive === false;

    if (role === "admin" || isBlocked) {
      continue;
    }

    processedUsers += 1;

    const uid = userDoc.id;
    const finance = await getUserFinanceSummary(uid);

    const message = buildFinanceMessage({
      ...finance,
      period: resolvedPeriod,
    });

    await createInAppNotification(uid, message.title, message.body, {
      type: "finance_analysis",
      priority: "medium",
      source: "admin_panel",
    });

    savedNotifications += 1;

    const pushResult = await sendPushNotificationToUser(
      userData,
      message.title,
      message.body,
    );

    sentCount += pushResult.successCount;

    if (pushResult.invalidTokens.length) {
      await userDoc.ref.update({
        notificationTokens: admin.firestore.FieldValue.arrayRemove(
          ...pushResult.invalidTokens,
        ),
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
    await assertAdmin(context.auth?.uid);

    return await sendFinanceNotificationsToUsers("manual");
  },
);

/// ==============================
/// RECORDATORIO DE DEUDAS MANUAL
/// SOLO DESDE PANEL ADMIN
/// ==============================
async function sendDebtReminderEmailsManual() {
  console.log("🚀 Ejecutando recordatorio manual de deudas");

  const now = getBogotaNow();
  const tomorrow = new Date(now);
  tomorrow.setDate(now.getDate() + 1);
  const dueDay = tomorrow.getDate();

  const debtsSnapshot = await admin
    .firestore()
    .collectionGroup("debts")
    .where("dia_pago", "==", dueDay)
    .get();

  const users = new Map();

  for (const doc of debtsSnapshot.docs) {
    const data = doc.data();
    const saldoActual = Number(data.saldo_actual) || 0;

    if (saldoActual <= 0) continue;

    const cuotaMensual = Number(data.cuota_mensual) || 0;
    const nombreDeuda = data.nombre || "Deuda";
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
  let processedUsers = 0;

  for (const [uid, debts] of users.entries()) {
    const userRef = admin.firestore().collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) continue;

    const userData = userDoc.data();
    const email = userData?.email;
    const name = userData?.name || "Usuario";

    if (!email) continue;

    processedUsers += 1;

    const subject = "Recordatorio: Mañana vence tu cuota de deuda";

    const debtRows = debts
      .map(
        (debt) =>
          `<li><strong>${debt.nombre}</strong>: cuota ${debt.cuota.toLocaleString(
            "es-CO",
            {
              style: "currency",
              currency: "COP",
            },
          )}, saldo ${debt.saldo.toLocaleString("es-CO", {
            style: "currency",
            currency: "COP",
          })}</li>`,
      )
      .join("");

    try {
      const info = await transporter.sendMail({
        from: `"KYBO App" <${emailUser}>`,
        to: email,
        subject,
        html: buildKyboEmailTemplate({
          preheader: "Recordatorio de pago",
          title: subject,
          message: `
            <p>Tus próximas cuotas vencen mañana. Ponte al día para evitar retrasos e intereses.</p>
            <p><strong>Vencimiento:</strong> mañana, día ${dueDay}</p>
            <ul style="padding-left:18px;margin:0;">${debtRows}</ul>
            <p style="margin-top:16px;">Revisa tu app para registrar tu pago.</p>
          `,
          buttonText: "Revisar mis deudas",
          buttonUrl: `${APP_URL}/#/debts`,
          userName: name,
          badge: "Recordatorio financiero",
        }),
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
    processedUsers,
    sentCount,
  };
}

exports.sendDebtReminderEmailsByAdmin = functionsV1.https.onCall(
  async (data, context) => {
    await assertAdmin(context.auth?.uid);

    return await sendDebtReminderEmailsManual();
  },
);

exports.sendCustomNotification = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    /// VALIDAR ADMIN
    await assertAdmin(request.auth?.uid);

    const {
      title,
      message,
      category,
      target,
      userId,
      sendApp,
      sendEmail,
      priority,
    } = request.data || {};

    if (!title || !message) {
      throw new HttpsError(
        "invalid-argument",
        "Título y mensaje son obligatorios",
      );
    }

    const usersSnapshot = await admin.firestore().collection("users").get();

    let totalRecipients = 0;
    let appSent = 0;
    let emailSent = 0;

    const campaignRef = await admin
      .firestore()
      .collection("notification_campaigns")
      .add({
        title,
        message,
        category,
        target,
        userId: userId || null,
        sendApp,
        sendEmail,
        priority,
        status: "sent",
        source: "admin_panel",
        scheduledAt: null,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        totalRecipients: 0,
        appSent: 0,
        emailSent: 0,
        readCount: 0,
        emailClickCount: 0,
        lastEmailClickAt: null,
        uniqueInteractionCount: 0,
        lastInteractionAt: null,
      });

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const uid = userDoc.id;

      const role = userData.role || "user";
      const isActive = userData.isActive !== false;

      if (role === "admin") continue;

      if (target === "active" && !isActive) continue;
      if (target === "inactive" && isActive) continue;
      if (target === "specific_user" && uid !== userId) continue;

      totalRecipients++;

      if (sendApp) {
        await createInAppNotification(uid, title, message, {
          type: category,
          priority,
          source: "admin_panel",
          campaignId: campaignRef.id,
        });

        // Cuenta como enviada a la app porque quedó guardada en Firestore
        appSent += 1;

        // Push opcional: si falla, no debe romper el envío
        try {
          await sendPushNotificationToUser(userData, title, message);
        } catch (pushError) {
          console.error("Error enviando push:", pushError);
        }
      }

      if (sendEmail && userData.email) {
        try {
          await transporter.sendMail({
            from: `"KYBO App" <${emailUser}>`,
            to: userData.email,
            subject: title,
            html: buildKyboEmailTemplate({
              preheader: title,
              title,
              message,
              buttonText: "Abrir KYBO",
              buttonUrl: buildTrackingUrl({
                campaignId: campaignRef.id,
                uid,
                targetPath: "/#/notifications",
              }),
              userName: userData.name || "",
              badge: "Nueva notificación",
            }),
          });

          emailSent++;
        } catch (e) {
          console.error("Error enviando email:", e);
        }
      }
    }

    await campaignRef.update({
      totalRecipients,
      appSent,
      emailSent,
    });

    return {
      success: true,
      totalRecipients,
      appSent,
      emailSent,
    };
  },
);

/// ==============================
/// PROCESAR CAMPAÑAS PROGRAMADAS
/// ==============================
exports.processScheduledNotifications = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "America/Bogota",
    region: "us-central1",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const scheduledSnapshot = await admin
      .firestore()
      .collection("notification_campaigns")
      .where("status", "==", "scheduled")
      .where("scheduledAt", "<=", now)
      .limit(10)
      .get();

    if (scheduledSnapshot.empty) {
      console.log("No hay campañas programadas pendientes.");
      return;
    }

    for (const campaignDoc of scheduledSnapshot.docs) {
      const campaignRef = campaignDoc.ref;
      const campaign = campaignDoc.data();
      const campaignId = campaignDoc.id;

      try {
        await campaignRef.update({
          status: "sending",
          processingAt: admin.firestore.FieldValue.serverTimestamp(),
          errorMessage: null,
        });

        const result = await sendScheduledCampaign(campaignId, campaign);

        await campaignRef.update({
          status: "sent",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          totalRecipients: result.totalRecipients,
          appSent: result.appSent,
          emailSent: result.emailSent,
          readCount: campaign.readCount || 0,
          emailClickCount: campaign.emailClickCount || 0,
          lastEmailClickAt: campaign.lastEmailClickAt || null,
          uniqueInteractionCount: campaign.uniqueInteractionCount || 0,
          lastInteractionAt: campaign.lastInteractionAt || null,
          errorMessage: null,
        });

        console.log("Campaña programada enviada:", campaignId);
      } catch (error) {
        console.error("Error enviando campaña programada:", campaignId, error);

        await campaignRef.update({
          status: "failed",
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          errorMessage: error.message || "Error desconocido",
        });
      }
    }
  },
);

async function sendScheduledCampaign(campaignId, campaign) {
  const {
    title,
    message,
    category,
    target,
    userId,
    sendApp,
    sendEmail,
    priority,
  } = campaign;

  if (!title || !message) {
    throw new Error("La campaña no tiene título o mensaje.");
  }

  const usersSnapshot = await admin.firestore().collection("users").get();

  let totalRecipients = 0;
  let appSent = 0;
  let emailSent = 0;

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const uid = userDoc.id;

    const role = userData.role || "user";
    const isActive = userData.isActive !== false;
    const isBlocked = userData.isBlocked === true;

    if (role === "admin") continue;

    if (target === "active" && !isActive) continue;
    if (target === "inactive" && isActive) continue;
    if (target === "blocked" && !isBlocked) continue;
    if (target === "specific_user" && uid !== userId) continue;

    totalRecipients++;

    if (sendApp) {
      await createInAppNotification(uid, title, message, {
        type: category,
        priority,
        source: "admin_panel",
        campaignId,
      });

      appSent++;

      try {
        await sendPushNotificationToUser(userData, title, message);
      } catch (pushError) {
        console.error("Error enviando push programado:", pushError);
      }
    }

    if (sendEmail && userData.email) {
      try {
        await transporter.sendMail({
          from: `"KYBO App" <${emailUser}>`,
          to: userData.email,
          subject: title,
          html: buildKyboEmailTemplate({
            preheader: title,
            title,
            message,
            buttonText: "Abrir KYBO",
            buttonUrl: buildTrackingUrl({
              campaignId,
              uid,
              targetPath: "/#/notifications",
            }),
            userName: userData.name || "",
            badge: "Campaña programada",
          }),
        });

        emailSent++;
      } catch (emailError) {
        console.error("Error enviando email programado:", emailError);
      }
    }
  }

  return {
    totalRecipients,
    appSent,
    emailSent,
  };
}

/// ==============================
/// MARCAR NOTIFICACIÓN COMO LEÍDA
/// ==============================
exports.markNotificationAsRead = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const { notificationId } = request.data || {};

    if (!notificationId) {
      throw new HttpsError(
        "invalid-argument",
        "notificationId es obligatorio.",
      );
    }

    const notificationRef = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("notifications")
      .doc(notificationId);

    return await admin.firestore().runTransaction(async (transaction) => {
      const notificationDoc = await transaction.get(notificationRef);

      if (!notificationDoc.exists) {
        throw new HttpsError("not-found", "La notificación no existe.");
      }

      const data = notificationDoc.data() || {};
      const campaignId = data.campaignId || null;

      let campaignRef = null;
      let interactionRef = null;
      let interactionDoc = null;

      if (campaignId) {
        campaignRef = admin
          .firestore()
          .collection("notification_campaigns")
          .doc(campaignId);

        interactionRef = campaignRef.collection("interactions").doc(uid);

        // ✅ Lectura primero
        interactionDoc = await transaction.get(interactionRef);
      }

      if (data.readTracked === true) {
        return {
          success: true,
          alreadyTracked: true,
          campaignId,
        };
      }

      transaction.update(notificationRef, {
        isRead: true,
        readTracked: true,
        readAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (campaignRef && interactionRef) {
        transaction.update(campaignRef, {
          readCount: admin.firestore.FieldValue.increment(1),
          lastInteractionAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.set(
          interactionRef,
          {
            uid,
            appRead: true,
            lastAppReadAt: admin.firestore.FieldValue.serverTimestamp(),
            lastInteractionAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        if (!interactionDoc.exists) {
          transaction.update(campaignRef, {
            uniqueInteractionCount: admin.firestore.FieldValue.increment(1),
          });
        }
      }

      return {
        success: true,
        alreadyTracked: false,
        campaignId,
      };
    });
  },
);

const registerFinanceAutomations = require("./financeAutomations");

Object.assign(
  exports,
  registerFinanceAutomations({
    admin,
    transporter,
    emailUser,
    getBogotaNow,
    toNumber,
    createInAppNotification,
    sendPushNotificationToUser,
    buildKyboEmailTemplate,
    createNotificationCampaign,
    buildTrackingUrl,
  }),
);

const registerBudgetAutomations = require("./budgetAutomations");

Object.assign(
  exports,
  registerBudgetAutomations({
    admin,
    transporter,
    emailUser,
    toNumber,
    createInAppNotification,
    sendPushNotificationToUser,
    buildKyboEmailTemplate,
    createNotificationCampaign,
    buildTrackingUrl,
  }),
);
