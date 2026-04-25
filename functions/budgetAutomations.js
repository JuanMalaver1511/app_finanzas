const { onDocumentCreated } = require("firebase-functions/v2/firestore");

module.exports = ({
  admin,
  transporter,
  emailUser,
  toNumber,
  createInAppNotification,
  sendPushNotificationToUser,
  buildKyboEmailTemplate,
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

  async function wasSentRecently(uid, dedupeKey, days = 7) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const snap = await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("notifications")
      .where("dedupeKey", "==", dedupeKey)
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(since))
      .limit(1)
      .get();

    return !snap.empty;
  }

  async function sendBudgetAlert({
    uid,
    userData,
    title,
    body,
    type,
    priority,
    dedupeKey,
    sendEmail = false,
  }) {
    const alreadySent = await wasSentRecently(uid, dedupeKey, 7);
    if (alreadySent) return;

    await createInAppNotification(uid, title, body, {
      type,
      priority,
      source: "budget_auto",
      dedupeKey,
    });

    try {
      const pushResult = await sendPushNotificationToUser(
        userData,
        title,
        body,
      );

      if (pushResult.invalidTokens.length) {
        await admin
          .firestore()
          .collection("users")
          .doc(uid)
          .update({
            notificationTokens: admin.firestore.FieldValue.arrayRemove(
              ...pushResult.invalidTokens,
            ),
          });
      }
    } catch (error) {
      console.error(`❌ Error push presupuesto para ${uid}:`, error);
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
            message: `
              <p>${body}</p>
              <p style="margin-top:16px;">Ingresa a KYBO para revisar tu presupuesto y ajustar tus gastos.</p>
            `,
            buttonText: "Revisar presupuesto",
            buttonUrl: "#",
            userName: userData.name || "",
            badge: "Alerta de presupuesto",
          }),
        });
      } catch (error) {
        console.error(
          `❌ Error email presupuesto para ${userData.email}:`,
          error,
        );
      }
    }
  }

  const checkBudgetOnExpenseCreated = onDocumentCreated(
    {
      document: "users/{uid}/transactions/{transactionId}",
      region: "us-central1",
    },
    async (event) => {
      const uid = event.params.uid;
      const snap = event.data;

      if (!snap) return;

      const transaction = snap.data() || {};

      // Solo gastos
      if (transaction.isIncome === true) return;

      const amount = toNumber(transaction.amount);
      if (amount <= 0) return;

      const categoryId =
        transaction.categoryId ||
        transaction.category ||
        transaction.categoryName ||
        null;

      if (!categoryId) return;

      const date = transaction.date?.toDate
        ? transaction.date.toDate()
        : new Date();

      const month = monthKey(date);

      const userRef = admin.firestore().collection("users").doc(uid);
      const userDoc = await userRef.get();

      if (!userDoc.exists) return;

      const userData = userDoc.data() || {};

      const role = userData.role || "user";
      const isBlocked =
        userData.isBlocked === true || userData.isActive === false;

      if (role === "admin" || isBlocked) return;

      // Buscar presupuesto del mes y categoría
      const budgetsSnap = await userRef
        .collection("budgets")
        .where("month", "==", month)
        .where("categoryId", "==", categoryId)
        .limit(1)
        .get();

      if (budgetsSnap.empty) return;

      const budgetDoc = budgetsSnap.docs[0];
      const budget = budgetDoc.data() || {};

      const budgetLimit = toNumber(
        budget.limit || budget.amount || budget.value || budget.budget,
      );

      if (budgetLimit <= 0) return;

      const transactionsSnap = await userRef
        .collection("transactions")
        .where("isIncome", "==", false)
        .where("categoryId", "==", categoryId)
        .get();

      let spent = 0;

      for (const doc of transactionsSnap.docs) {
        const data = doc.data() || {};
        const tDate = data.date?.toDate ? data.date.toDate() : null;

        if (!tDate) continue;
        if (monthKey(tDate) !== month) continue;

        spent += toNumber(data.amount);
      }

      const percent = budgetLimit > 0 ? spent / budgetLimit : 0;
      const categoryName =
        budget.categoryName ||
        transaction.categoryName ||
        transaction.category ||
        "esta categoría";

      if (percent >= 1.2) {
        await sendBudgetAlert({
          uid,
          userData,
          title: "Presupuesto superado significativamente",
          body: `Has usado ${formatCOP(spent)} de ${formatCOP(budgetLimit)} en ${categoryName}. Ya superaste el presupuesto en más del 20%.`,
          type: "budget_critical",
          priority: "high",
          dedupeKey: `budget_critical_${month}_${categoryId}`,
          sendEmail: true,
        });

        return;
      }

      if (percent >= 1) {
        await sendBudgetAlert({
          uid,
          userData,
          title: "Presupuesto superado",
          body: `Ya superaste tu presupuesto de ${categoryName}. Llevas ${formatCOP(spent)} de ${formatCOP(budgetLimit)}.`,
          type: "budget_exceeded",
          priority: "high",
          dedupeKey: `budget_exceeded_${month}_${categoryId}`,
          sendEmail: false,
        });

        return;
      }

      if (percent >= 0.8) {
        await sendBudgetAlert({
          uid,
          userData,
          title: "Estás cerca de tu límite de presupuesto",
          body: `Ya usaste aproximadamente el ${Math.round(percent * 100)}% de tu presupuesto en ${categoryName}. Llevas ${formatCOP(spent)} de ${formatCOP(budgetLimit)}.`,
          type: "budget_warning",
          priority: "medium",
          dedupeKey: `budget_warning_${month}_${categoryId}`,
          sendEmail: false,
        });
      }
    },
  );

  return {
    checkBudgetOnExpenseCreated,
  };
};
