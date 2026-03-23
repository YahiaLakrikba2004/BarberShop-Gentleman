import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helpers ────────────────────────────────────────────────────────────────

async function getStaffTokens(): Promise<string[]> {
  const snap = await db
    .collection("users")
    .where("role", "in", ["admin", "barber"])
    .get();
  const tokens: string[] = [];
  snap.forEach((doc) => {
    const token = doc.data().fcmToken as string | undefined;
    if (token) tokens.push(token);
  });
  return tokens;
}

async function getUserToken(userId: string): Promise<string | null> {
  if (!userId) return null;
  const doc = await db.collection("users").doc(userId).get();
  return (doc.data()?.fcmToken as string | undefined) ?? null;
}

function formatTime(ts: admin.firestore.Timestamp): string {
  const d = ts.toDate();
  const h = d.getHours().toString().padStart(2, "0");
  const m = d.getMinutes().toString().padStart(2, "0");
  return `${h}:${m}`;
}

function formatDate(ts: admin.firestore.Timestamp): string {
  const d = ts.toDate();
  const months = [
    "gen", "feb", "mar", "apr", "mag", "giu",
    "lug", "ago", "set", "ott", "nov", "dic",
  ];
  return `${d.getDate()} ${months[d.getMonth()]}`;
}

async function sendToTokens(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  if (tokens.length === 0) return;

  const unique = [...new Set(tokens)];

  const messages: admin.messaging.Message[] = unique.map((token) => ({
    token,
    notification: {title, body},
    data: data ?? {},
    android: {priority: "high"},
    apns: {
      payload: {aps: {sound: "default", badge: 1}},
    },
  }));

  const results = await messaging.sendEach(messages);
  functions.logger.info(
    `FCM sent: ${results.successCount} ok, ${results.failureCount} fail`
  );

  // Clean up stale tokens
  const staleTokens: string[] = [];
  results.responses.forEach((res, i) => {
    if (
      !res.success &&
      (res.error?.code === "messaging/invalid-registration-token" ||
        res.error?.code === "messaging/registration-token-not-registered")
    ) {
      staleTokens.push(unique[i]);
    }
  });
  if (staleTokens.length > 0) {
    const batch = db.batch();
    const snap = await db
      .collection("users")
      .where("fcmToken", "in", staleTokens)
      .get();
    snap.forEach((doc) =>
      batch.update(doc.ref, {
        fcmToken: admin.firestore.FieldValue.delete(),
      })
    );
    await batch.commit();
    functions.logger.info(`Cleaned ${staleTokens.length} stale tokens`);
  }
}

/** Write a reminder document to scheduledNotifications collection */
async function scheduleReminder(
  id: string,
  customerId: string,
  scheduledFor: admin.firestore.Timestamp,
  title: string,
  body: string
): Promise<void> {
  if (scheduledFor.toDate() <= new Date()) return; // already past
  await db.collection("scheduledNotifications").doc(id).set({
    customerId,
    scheduledFor,
    title,
    body,
    sent: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** Delete all reminder documents for an appointment */
async function deleteReminders(appointmentId: string): Promise<void> {
  const ids = [
    `${appointmentId}_1h`,
    `${appointmentId}_24h`,
    `${appointmentId}_reengage`,
    `${appointmentId}_barber30m`,
    `${appointmentId}_review`,
  ];
  const batch = db.batch();
  ids.forEach((id) => batch.delete(db.collection("scheduledNotifications").doc(id)));
  await batch.commit();
}

// ─── Trigger: new appointment created ────────────────────────────────────────

export const onAppointmentCreated = onDocumentCreated(
  "appointments/{appointmentId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const appointmentId = event.params.appointmentId;
    const date = data.date as admin.firestore.Timestamp;
    const customerId = data.customerId as string;
    const customerName = data.customerName as string;
    const serviceName = data.serviceName as string;
    const barberName = data.barberName as string;
    const source = (data.source as string | undefined) ?? "app";

    // 1. Notify staff immediately
    const sourceLabel = source === "web" ? " [WEB]" : "";
    const staffTokens = await getStaffTokens();
    await sendToTokens(
      staffTokens,
      `Nuova prenotazione${sourceLabel}`,
      `${customerName} — ${serviceName} con ${barberName} il ${formatDate(date)} alle ${formatTime(date)}`,
      {route: "/admin/appointments", appointmentId}
    );

    // 2. Notify customer immediately: booking confirmed
    if (customerId) {
      const customerToken = await getUserToken(customerId);
      if (customerToken) {
        await sendToTokens(
          [customerToken],
          "Prenotazione confermata ✓",
          `${serviceName} con ${barberName} il ${formatDate(date)} alle ${formatTime(date)} — ci vediamo!`,
          {route: "/appointments"}
        );
      }
    }

    // 3. Schedule reminders (only for registered users with a customerId)
    if (!customerId) return;

    const dateMs = date.toDate().getTime();

    // 24h reminder → customer
    const ts24h = admin.firestore.Timestamp.fromMillis(dateMs - 24 * 60 * 60 * 1000);
    await scheduleReminder(
      `${appointmentId}_24h`,
      customerId,
      ts24h,
      "Appuntamento domani",
      `Domani alle ${formatTime(date)} — ${serviceName} con ${barberName}.`
    );

    // 1h reminder → customer
    const ts1h = admin.firestore.Timestamp.fromMillis(dateMs - 60 * 60 * 1000);
    await scheduleReminder(
      `${appointmentId}_1h`,
      customerId,
      ts1h,
      `${serviceName} tra 1 ora`,
      `Alle ${formatTime(date)} con ${barberName}. Sei pronto?`
    );

    // 30 min reminder → barber
    const barberId = data.barberId as string;
    const ts30mBarber = admin.firestore.Timestamp.fromMillis(dateMs - 30 * 60 * 1000);
    await scheduleReminder(
      `${appointmentId}_barber30m`,
      barberId,
      ts30mBarber,
      "Appuntamento tra 30 minuti",
      `${customerName} — ${serviceName} alle ${formatTime(date)}.`
    );

    // Re-engagement: 21 days after → customer
    const tsReengage = admin.firestore.Timestamp.fromMillis(dateMs + 21 * 24 * 60 * 60 * 1000);
    await scheduleReminder(
      `${appointmentId}_reengage`,
      customerId,
      tsReengage,
      "È ora di tornare! ✂️",
      "Sono passate 3 settimane. Prenota il prossimo appuntamento da The Gentlemen."
    );
  }
);

// ─── Trigger: appointment status updated ─────────────────────────────────────

export const onAppointmentUpdated = onDocumentUpdated(
  "appointments/{appointmentId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevStatus = before.status as string;
    const newStatus = after.status as string;
    if (prevStatus === newStatus) return;

    const appointmentId = event.params.appointmentId;
    const date = after.date as admin.firestore.Timestamp;
    const customerId = after.customerId as string;
    const customerName = after.customerName as string;
    const serviceName = after.serviceName as string;

    if (newStatus === "cancelled") {
      // Cancel scheduled reminders
      await deleteReminders(appointmentId);

      // Notify staff if the customer cancelled
      const staffTokens = await getStaffTokens();
      await sendToTokens(
        staffTokens,
        "Appuntamento cancellato",
        `${customerName} ha cancellato: ${serviceName} il ${formatDate(date)} alle ${formatTime(date)}.`,
        {route: "/admin/appointments"}
      );

      // Notify the customer
      const token = await getUserToken(customerId);
      if (token) {
        await sendToTokens(
          [token],
          "Appuntamento cancellato",
          `Il tuo ${serviceName} del ${formatDate(date)} alle ${formatTime(date)} è stato cancellato.`,
          {route: "/appointments"}
        );
      }
    }

    if (newStatus === "completed") {
      // Schedule review prompt 2 hours after the appointment
      const dateMs = date.toDate().getTime();
      const tsReview = admin.firestore.Timestamp.fromMillis(dateMs + 2 * 60 * 60 * 1000);
      await scheduleReminder(
        `${event.params.appointmentId}_review`,
        customerId,
        tsReview,
        "Com'è andata? ⭐",
        `Speriamo ti sia piaciuto il ${serviceName}! Lascia una recensione su Google Maps.`
      );
    }

    if (newStatus === "noShow") {
      const staffTokens = await getStaffTokens();
      await sendToTokens(
        staffTokens,
        "Cliente non presentato",
        `${customerName} non si è presentato per ${serviceName} alle ${formatTime(date)}.`,
        {route: "/admin/appointments"}
      );
    }
  }
);

// ─── Trigger: appointment hard-deleted ───────────────────────────────────────

export const onAppointmentDeleted = onDocumentDeleted(
  "appointments/{appointmentId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const appointmentId = event.params.appointmentId;
    const date = data.date as admin.firestore.Timestamp;
    const customerId = data.customerId as string;
    const serviceName = data.serviceName as string;

    // Cancel any pending reminders
    await deleteReminders(appointmentId);

    // Notify the customer
    const token = await getUserToken(customerId);
    if (!token) return;

    await sendToTokens(
      [token],
      "Appuntamento cancellato",
      `Il tuo ${serviceName} del ${formatDate(date)} alle ${formatTime(date)} è stato cancellato.`,
      {route: "/appointments"}
    );
  }
);

// ─── Trigger: barber marks unavailable ───────────────────────────────────────

export const onBarberUnavailable = onDocumentUpdated(
  "barbers/{barberId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevDates = (before.unavailableDates as string[] | undefined) ?? [];
    const newDates = (after.unavailableDates as string[] | undefined) ?? [];
    const added = newDates.filter((d) => !prevDates.includes(d));

    if (added.length === 0) return;

    const barberName = after.name as string;

    for (const dateStr of added) {
      const start = new Date(dateStr);
      start.setHours(0, 0, 0, 0);
      const end = new Date(dateStr);
      end.setHours(23, 59, 59, 999);

      const snap = await db
        .collection("appointments")
        .where("barberId", "==", event.params.barberId)
        .where("status", "in", ["pending", "confirmed"])
        .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
        .where("date", "<=", admin.firestore.Timestamp.fromDate(end))
        .get();

      for (const doc of snap.docs) {
        const apt = doc.data();
        const token = await getUserToken(apt.customerId as string);
        if (!token) continue;
        await sendToTokens(
          [token],
          "Appuntamento da riprogrammare",
          `${barberName} non sarà disponibile il ${dateStr}. Contattaci per riprogrammare il tuo ${apt.serviceName as string}.`,
          {route: "/appointments", appointmentId: doc.id}
        );
      }
    }
  }
);

// ─── Trigger: announcement → notify all clients ───────────────────────────────
// Admin writes to announcements/{id} → FCM sent to all clients

export const onAnnouncementCreated = onDocumentCreated(
  "announcements/{announcementId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const title = (data.title as string | undefined) ?? "The Gentlemen";
    const body = data.body as string;
    if (!body) return;

    const snap = await db
      .collection("users")
      .where("role", "==", "client")
      .get();

    const tokens: string[] = [];
    snap.forEach((doc) => {
      const token = doc.data().fcmToken as string | undefined;
      if (token) tokens.push(token);
    });

    await sendToTokens(tokens, title, body, {route: "/"});

    // Mark as delivered
    await event.data?.ref.update({sentAt: admin.firestore.FieldValue.serverTimestamp()});
  }
);

// ─── Scheduled: daily summary to each barber at 08:00 Rome time ──────────────

export const dailyBarberSummary = onSchedule(
  {schedule: "0 8 * * *", timeZone: "Europe/Rome"},
  async () => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

    // Get all barbers
    const barbersSnap = await db.collection("barbers").get();

    for (const barberDoc of barbersSnap.docs) {
      const barberId = barberDoc.id;
      const barberName = barberDoc.data().name as string;

      // Get today's appointments for this barber (pending + confirmed)
      const aptsSnap = await db
        .collection("appointments")
        .where("barberId", "==", barberId)
        .where("status", "in", ["pending", "confirmed"])
        .where("date", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
        .where("date", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
        .orderBy("date")
        .get();

      if (aptsSnap.empty) continue;

      const count = aptsSnap.size;
      const firstApt = aptsSnap.docs[0].data();
      const firstTime = formatTime(firstApt.date as admin.firestore.Timestamp);

      const token = await getUserToken(barberId);
      if (!token) continue;

      await sendToTokens(
        [token],
        `Buongiorno ${barberName}! 💈`,
        `Oggi hai ${count} appuntament${count === 1 ? "o" : "i"}. Il primo alle ${firstTime}.`,
        {route: "/calendar"}
      );
    }
  }
);

// ─── Scheduled: process pending reminders every 15 minutes ───────────────────

export const processScheduledNotifications = onSchedule(
  "every 15 minutes",
  async () => {
    const now = admin.firestore.Timestamp.now();

    const snap = await db
      .collection("scheduledNotifications")
      .where("scheduledFor", "<=", now)
      .where("sent", "==", false)
      .get();

    if (snap.empty) return;

    functions.logger.info(`Processing ${snap.size} scheduled notifications`);

    for (const doc of snap.docs) {
      const data = doc.data();
      const customerId = data.customerId as string;
      const title = data.title as string;
      const body = data.body as string;

      try {
        const token = await getUserToken(customerId);
        if (token) {
          await sendToTokens([token], title, body, {route: "/appointments"});
        }
      } catch (e) {
        functions.logger.error(`Error sending reminder ${doc.id}:`, e);
      }

      await doc.ref.update({sent: true, sentAt: now});
    }
  }
);
