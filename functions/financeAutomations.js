const { onSchedule } = require("firebase-functions/v2/scheduler");

module.exports = ({
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
}) => {
  const formatCOP = (value) =>
    Number(value || 0).toLocaleString("es-CO", {
      style: "currency",
      currency: "COP",
      maximumFractionDigits: 0,
    });

  function monthKey(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
  }

  function dateKey(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
  }

  async function getEligibleUsers() {
    const snap = await admin.firestore().collection("users").get();

    return snap.docs.filter((doc) => {
      const data = doc.data() || {};
      const role = data.role || "user";
      const blocked = data.isBlocked === true || data.isActive === false;
      return role !== "admin" && !blocked;
    });
  }

  async function wasAutomationSent(uid, key, days) {
    const ref = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("automation_logs")
      .doc(key);

    const doc = await ref.get();

    if (!doc.exists) return false;

    const lastSentAt = doc.data()?.lastSentAt?.toDate?.();
    if (!lastSentAt) return false;

    const diffDays =
      (Date.now() - lastSentAt.getTime()) / (1000 * 60 * 60 * 24);

    return diffDays < days;
  }

  async function markAutomationSent(uid, key) {
    await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("automation_logs")
      .doc(key)
      .set(
        {
          key,
          lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  }

  async function getUserMonthSummary(uid) {
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

  async function getUserWeekSummary(uid, startDate, endDate) {
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
      if (date < startDate || date > endDate) continue;

      if (isIncome) {
        ingresos += amount;
      } else {
        gastos += amount;
      }
    }

    return {
      ingresos,
      gastos,
      balance: ingresos - gastos,
    };
  }

  function getPreviousWeekRange() {
    const now = getBogotaNow();
    const day = now.getDay(); // domingo 0, lunes 1
    const mondayThisWeek = new Date(now);
    mondayThisWeek.setDate(now.getDate() - ((day + 6) % 7));
    mondayThisWeek.setHours(0, 0, 0, 0);

    const start = new Date(mondayThisWeek);
    start.setDate(mondayThisWeek.getDate() - 7);

    const end = new Date(mondayThisWeek);
    end.setMilliseconds(-1);

    return { start, end };
  }

  function buildFinanceAlert(finance) {
    const { ingresos, gastos, deudas, balance } = finance;

    if (balance < 0) {
      return {
        title: "Alerta: balance negativo",
        body: `Tu balance actual es ${formatCOP(balance)}. Revisa tus gastos recientes y ajusta tu presupuesto para recuperar estabilidad.`,
        type: "finance_alert",
        priority: "high",
        sendEmail: true,
        appCooldownDays: 2,
        emailCooldownDays: 7,
      };
    }

    if (ingresos > 0 && gastos >= ingresos * 0.9) {
      const isCritical = gastos >= ingresos;

      return {
        title: "Tus gastos están cerca de tus ingresos",
        body: `Has registrado gastos por ${formatCOP(gastos)} frente a ingresos de ${formatCOP(ingresos)}. Revisa tu presupuesto para evitar un desbalance.`,
        type: "spending_alert",
        priority: isCritical ? "high" : "medium",
        sendEmail: isCritical,
        appCooldownDays: 2,
        emailCooldownDays: 7,
      };
    }

    if (ingresos > 0 && deudas >= ingresos * 0.4) {
      return {
        title: "Revisa tus compromisos de deuda",
        body: `Tus cuotas o compromisos de deuda suman aproximadamente ${formatCOP(deudas)}. Prioriza pagos y cuida tu flujo mensual.`,
        type: "debt_alert",
        priority: "medium",
        sendEmail: true,
        appCooldownDays: 2,
        emailCooldownDays: 7,
      };
    }

    return null;
  }

  async function sendAutomaticFinanceMessage(userDoc, message, campaignRef) {
    const uid = userDoc.id;
    const userData = userDoc.data() || {};

    const appKey = `${message.type}_app`;
    const emailKey = `${message.type}_email`;

    let app = 0;
    let push = 0;
    let email = 0;

    const appAlreadySent = await wasAutomationSent(
      uid,
      appKey,
      message.appCooldownDays || 2,
    );

    if (!appAlreadySent) {
      await createInAppNotification(uid, message.title, message.body, {
        type: message.type,
        priority: message.priority,
        source: "finance_auto",
        dedupeKey: appKey,
        campaignId: campaignRef.id,
      });

      await markAutomationSent(uid, appKey);
      app++;

      try {
        const pushResult = await sendPushNotificationToUser(
          userData,
          message.title,
          message.body,
        );

        push += pushResult.successCount;

        if (pushResult.invalidTokens.length) {
          await userDoc.ref.update({
            notificationTokens: admin.firestore.FieldValue.arrayRemove(
              ...pushResult.invalidTokens,
            ),
          });
        }
      } catch (error) {
        console.error(`❌ Error push automático para ${uid}:`, error);
      }
    }

    if (message.sendEmail === true && userData.email) {
      const emailAlreadySent = await wasAutomationSent(
        uid,
        emailKey,
        message.emailCooldownDays || 7,
      );

      if (!emailAlreadySent) {
        try {
          await transporter.sendMail({
            from: `"KYBO App" <${emailUser}>`,
            to: userData.email,
            subject: message.title,
            html: buildKyboEmailTemplate({
              preheader: message.title,
              title: message.title,
              message: `
                <p>${message.body}</p>
                <p style="margin-top:16px;">Ingresa a KYBO para revisar tus movimientos y mantener el control.</p>
              `,
              buttonText: "Revisar mis finanzas",
              buttonUrl: `https://trackemailclick-wnfkevrrxa-uc.a.run.app?campaignId=${campaignRef.id}&uid=${uid}&destination=${encodeURIComponent("https://control-financiero-app-b9f91.web.app/#/notifications")}`,
              userName: userData.name || "",
              badge: "Análisis financiero",
            }),
          });

          await markAutomationSent(uid, emailKey);
          email++;
        } catch (error) {
          console.error(
            `❌ Error email automático para ${userData.email}:`,
            error,
          );
        }
      }
    }

    if (app > 0 || email > 0) {
      await campaignRef.update({
        totalRecipients: admin.firestore.FieldValue.increment(1),
        appSent: admin.firestore.FieldValue.increment(app),
        emailSent: admin.firestore.FieldValue.increment(email),
      });
    }

    return { app, push, email };
  }

  async function processFinanceAutomationCampaign({
    users,
    campaignTitle,
    campaignMessage,
    category,
    priority,
    sendEmail,
    buildMessageForUser,
  }) {
    const campaignRef = await createNotificationCampaign({
      title: campaignTitle,
      message: campaignMessage,
      category,
      campaignType: "finance_auto",
      source: "finance_automation",
      target: "automatic",
      sendApp: true,
      sendEmail,
      priority,
    });

    let app = 0;
    let push = 0;
    let email = 0;

    for (const item of users) {
      const userDoc = item.userDoc || item;
      const message = await buildMessageForUser(item);

      if (!message) continue;

      const result = await sendAutomaticFinanceMessage(
        userDoc,
        message,
        campaignRef,
      );

      app += result.app;
      push += result.push;
      email += result.email;
    }

    return {
      success: true,
      campaignId: campaignRef.id,
      app,
      push,
      email,
    };
  }

  const sendFinanceAlertsScheduled = onSchedule(
    {
      schedule: "0 20 * * 1,3,5",
      timeZone: "America/Bogota",
    },
    async () => {
      const users = await getEligibleUsers();

      return await processFinanceAutomationCampaign({
        users,
        campaignTitle: "Alertas financieras automáticas",
        campaignMessage:
          "KYBO revisó tus finanzas y encontró alertas importantes para ayudarte a mantener el control.",
        category: "finance_alerts",
        priority: "high",
        sendEmail: true,
        buildMessageForUser: async (userDoc) => {
          const finance = await getUserMonthSummary(userDoc.id);
          return buildFinanceAlert(finance);
        },
      });
    },
  );

  const sendNoMovementsReminderScheduled = onSchedule(
    {
      schedule: "0 19 * * 2,5",
      timeZone: "America/Bogota",
    },
    async () => {
      const users = await getEligibleUsers();

      return await processFinanceAutomationCampaign({
        users,
        campaignTitle: "Recordatorio de movimientos",
        campaignMessage:
          "KYBO recordó a los usuarios registrar sus ingresos y gastos para mantener una visión clara de su dinero.",
        category: "no_movements_reminder",
        priority: "medium",
        sendEmail: true,
        buildMessageForUser: async (userDoc) => {
          const finance = await getUserMonthSummary(userDoc.id);

          if (
            finance.ingresos > 0 ||
            finance.gastos > 0 ||
            finance.deudas > 0
          ) {
            return null;
          }

          return {
            title: "Organiza tus finanzas esta semana",
            body: "Aún no registras movimientos este mes. Dedica unos minutos a ingresar tus ingresos y gastos para tener una visión clara de tu dinero.",
            type: "no_movements_reminder",
            priority: "medium",
            sendEmail: true,
            appCooldownDays: 3,
            emailCooldownDays: 3,
          };
        },
      });
    },
  );

  const sendMotivationalFinanceScheduled = onSchedule(
    {
      schedule: "0 9 * * 0",
      timeZone: "America/Bogota",
    },
    async () => {
      const users = await getEligibleUsers();

      return await processFinanceAutomationCampaign({
        users,
        campaignTitle: "Pequeños hábitos, grandes cambios",
        campaignMessage:
          "Registrar tus movimientos de forma constante te ayuda a tomar mejores decisiones y mantener el control de tu dinero.",
        category: "weekly_motivation",
        priority: "low",
        sendEmail: true,
        buildMessageForUser: async () => ({
          title: "Pequeños hábitos, grandes cambios",
          body: "Registrar tus movimientos de forma constante te ayuda a tomar mejores decisiones y mantener el control de tu dinero.",
          type: "weekly_motivation",
          priority: "low",
          sendEmail: true,
          appCooldownDays: 7,
          emailCooldownDays: 7,
        }),
      });
    },
  );

  const sendWeeklyFinanceSummaryScheduled = onSchedule(
    {
      schedule: "0 8 * * 1",
      timeZone: "America/Bogota",
    },
    async () => {
      const users = await getEligibleUsers();
      const { start, end } = getPreviousWeekRange();

      return await processFinanceAutomationCampaign({
        users,
        campaignTitle: "Resumen financiero semanal",
        campaignMessage: `Resumen automático de la semana ${dateKey(start)}.`,
        category: `weekly_finance_summary_${dateKey(start)}`,
        priority: "medium",
        sendEmail: true,
        buildMessageForUser: async (userDoc) => {
          const finance = await getUserWeekSummary(userDoc.id, start, end);

          return {
            title: "Resumen financiero semanal",
            body: `La semana anterior cerraste con ingresos de ${formatCOP(finance.ingresos)}, gastos de ${formatCOP(finance.gastos)} y un balance de ${formatCOP(finance.balance)}.`,
            type: `weekly_finance_summary_${dateKey(start)}`,
            priority: "medium",
            sendEmail: true,
            appCooldownDays: 7,
            emailCooldownDays: 7,
          };
        },
      });
    },
  );

  const sendDebtUpcomingScheduled = onSchedule(
    {
      schedule: "0 8 * * *",
      timeZone: "America/Bogota",
    },
    async () => {
      const now = getBogotaNow();
      const tomorrow = new Date(now);
      tomorrow.setDate(now.getDate() + 1);

      const dueDay = tomorrow.getDate();
      const currentMonth = monthKey(tomorrow);

      const debtsSnapshot = await admin
        .firestore()
        .collectionGroup("debts")
        .where("dia_pago", "==", dueDay)
        .get();

      const usersMap = new Map();

      for (const doc of debtsSnapshot.docs) {
        const data = doc.data();
        const saldoActual = toNumber(data.saldo_actual);

        if (saldoActual <= 0) continue;

        const userDocRef = doc.ref.parent.parent;
        if (!userDocRef) continue;

        const uid = userDocRef.id;

        const current = usersMap.get(uid) || [];
        current.push({
          id: doc.id,
          nombre: data.nombre || "Deuda",
          cuota: toNumber(data.cuota_mensual),
          saldo: saldoActual,
          diaPago: dueDay,
        });

        usersMap.set(uid, current);
      }

      const users = [];

      for (const [uid, debts] of usersMap.entries()) {
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(uid)
          .get();

        if (!userDoc.exists) continue;

        const userData = userDoc.data() || {};
        const role = userData.role || "user";
        const blocked =
          userData.isBlocked === true || userData.isActive === false;

        if (role === "admin" || blocked) continue;

        users.push({
          userDoc,
          debts,
        });
      }

      return await processFinanceAutomationCampaign({
        users,
        campaignTitle: "Recordatorio de deudas próximas",
        campaignMessage: `Recordatorio automático para deudas que vencen mañana, día ${dueDay}.`,
        category: `debt_upcoming_${currentMonth}_${dueDay}`,
        priority: "high",
        sendEmail: true,
        buildMessageForUser: async ({ debts }) => {
          const rows = debts
            .map((debt) => `${debt.nombre}: cuota ${formatCOP(debt.cuota)}`)
            .join(", ");

          return {
            title: "Recordatorio de pago para mañana",
            body: `Mañana vence una o más cuotas: ${rows}. Registra tu pago en KYBO para mantener tus deudas bajo control.`,
            type: `debt_upcoming_${currentMonth}_${dueDay}`,
            priority: "high",
            sendEmail: true,
            appCooldownDays: 3,
            emailCooldownDays: 3,
          };
        },
      });
    },
  );

  return {
    sendFinanceAlertsScheduled,
    sendNoMovementsReminderScheduled,
    sendMotivationalFinanceScheduled,
    sendWeeklyFinanceSummaryScheduled,
    sendDebtUpcomingScheduled,
  };
};
