"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processScheduledNotifications = exports.dailyBarberSummary = exports.onAnnouncementCreated = exports.onBarberUnavailable = exports.onAppointmentDeleted = exports.onAppointmentUpdated = exports.onAppointmentCreated = void 0;
const admin = require("firebase-admin");
const functions = require("firebase-functions/v2");
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// ─── Helpers ────────────────────────────────────────────────────────────────
async function getStaffTokens() {
    const snap = await db
        .collection("users")
        .where("role", "in", ["admin", "barber"])
        .get();
    const tokens = [];
    snap.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token)
            tokens.push(token);
    });
    return tokens;
}
async function getUserToken(userId) {
    var _a, _b;
    if (!userId)
        return null;
    const doc = await db.collection("users").doc(userId).get();
    return (_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken) !== null && _b !== void 0 ? _b : null;
}
function formatTime(ts) {
    const d = ts.toDate();
    const h = d.getHours().toString().padStart(2, "0");
    const m = d.getMinutes().toString().padStart(2, "0");
    return `${h}:${m}`;
}
function formatDate(ts) {
    const d = ts.toDate();
    const months = [
        "gen", "feb", "mar", "apr", "mag", "giu",
        "lug", "ago", "set", "ott", "nov", "dic",
    ];
    return `${d.getDate()} ${months[d.getMonth()]}`;
}
async function sendToTokens(tokens, title, body, data) {
    if (tokens.length === 0)
        return;
    const unique = [...new Set(tokens)];
    const messages = unique.map((token) => ({
        token,
        notification: { title, body },
        data: data !== null && data !== void 0 ? data : {},
        android: { priority: "high" },
        apns: {
            payload: { aps: { sound: "default", badge: 1 } },
        },
    }));
    const results = await messaging.sendEach(messages);
    functions.logger.info(`FCM sent: ${results.successCount} ok, ${results.failureCount} fail`);
    // Clean up stale tokens
    const staleTokens = [];
    results.responses.forEach((res, i) => {
        var _a, _b;
        if (!res.success &&
            (((_a = res.error) === null || _a === void 0 ? void 0 : _a.code) === "messaging/invalid-registration-token" ||
                ((_b = res.error) === null || _b === void 0 ? void 0 : _b.code) === "messaging/registration-token-not-registered")) {
            staleTokens.push(unique[i]);
        }
    });
    if (staleTokens.length > 0) {
        const batch = db.batch();
        const snap = await db
            .collection("users")
            .where("fcmToken", "in", staleTokens)
            .get();
        snap.forEach((doc) => batch.update(doc.ref, {
            fcmToken: admin.firestore.FieldValue.delete(),
        }));
        await batch.commit();
        functions.logger.info(`Cleaned ${staleTokens.length} stale tokens`);
    }
}
/** Write a reminder document to scheduledNotifications collection */
async function scheduleReminder(id, customerId, scheduledFor, title, body) {
    if (scheduledFor.toDate() <= new Date())
        return; // already past
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
async function deleteReminders(appointmentId) {
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
exports.onAppointmentCreated = (0, firestore_1.onDocumentCreated)("appointments/{appointmentId}", async (event) => {
    var _a, _b;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const appointmentId = event.params.appointmentId;
    const date = data.date;
    const customerId = data.customerId;
    const customerName = data.customerName;
    const serviceName = data.serviceName;
    const barberName = data.barberName;
    const source = (_b = data.source) !== null && _b !== void 0 ? _b : "app";
    // 1. Notify staff immediately
    const sourceLabel = source === "web" ? " [WEB]" : "";
    const staffTokens = await getStaffTokens();
    await sendToTokens(staffTokens, `Nuova prenotazione${sourceLabel}`, `${customerName} — ${serviceName} con ${barberName} il ${formatDate(date)} alle ${formatTime(date)}`, { route: "/admin/appointments", appointmentId });
    // 2. Notify customer immediately: booking confirmed
    if (customerId) {
        const customerToken = await getUserToken(customerId);
        if (customerToken) {
            await sendToTokens([customerToken], "Prenotazione confermata ✓", `${serviceName} con ${barberName} il ${formatDate(date)} alle ${formatTime(date)} — ci vediamo!`, { route: "/appointments" });
        }
    }
    // 3. Schedule reminders (only for registered users with a customerId)
    if (!customerId)
        return;
    const dateMs = date.toDate().getTime();
    // 24h reminder → customer
    const ts24h = admin.firestore.Timestamp.fromMillis(dateMs - 24 * 60 * 60 * 1000);
    await scheduleReminder(`${appointmentId}_24h`, customerId, ts24h, "Appuntamento domani", `Domani alle ${formatTime(date)} — ${serviceName} con ${barberName}.`);
    // 1h reminder → customer
    const ts1h = admin.firestore.Timestamp.fromMillis(dateMs - 60 * 60 * 1000);
    await scheduleReminder(`${appointmentId}_1h`, customerId, ts1h, `${serviceName} tra 1 ora`, `Alle ${formatTime(date)} con ${barberName}. Sei pronto?`);
    // 30 min reminder → barber
    const barberId = data.barberId;
    const ts30mBarber = admin.firestore.Timestamp.fromMillis(dateMs - 30 * 60 * 1000);
    await scheduleReminder(`${appointmentId}_barber30m`, barberId, ts30mBarber, "Appuntamento tra 30 minuti", `${customerName} — ${serviceName} alle ${formatTime(date)}.`);
    // Re-engagement: 21 days after → customer
    const tsReengage = admin.firestore.Timestamp.fromMillis(dateMs + 21 * 24 * 60 * 60 * 1000);
    await scheduleReminder(`${appointmentId}_reengage`, customerId, tsReengage, "È ora di tornare! ✂️", "Sono passate 3 settimane. Prenota il prossimo appuntamento da The Gentlemen.");
});
// ─── Trigger: appointment status updated ─────────────────────────────────────
exports.onAppointmentUpdated = (0, firestore_1.onDocumentUpdated)("appointments/{appointmentId}", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const prevStatus = before.status;
    const newStatus = after.status;
    if (prevStatus === newStatus)
        return;
    const appointmentId = event.params.appointmentId;
    const date = after.date;
    const customerId = after.customerId;
    const customerName = after.customerName;
    const serviceName = after.serviceName;
    if (newStatus === "cancelled") {
        // Cancel scheduled reminders
        await deleteReminders(appointmentId);
        // Notify staff if the customer cancelled
        const staffTokens = await getStaffTokens();
        await sendToTokens(staffTokens, "Appuntamento cancellato", `${customerName} ha cancellato: ${serviceName} il ${formatDate(date)} alle ${formatTime(date)}.`, { route: "/admin/appointments" });
        // Notify the customer
        const token = await getUserToken(customerId);
        if (token) {
            await sendToTokens([token], "Appuntamento cancellato", `Il tuo ${serviceName} del ${formatDate(date)} alle ${formatTime(date)} è stato cancellato.`, { route: "/appointments" });
        }
    }
    if (newStatus === "completed") {
        // Schedule review prompt 2 hours after the appointment
        const dateMs = date.toDate().getTime();
        const tsReview = admin.firestore.Timestamp.fromMillis(dateMs + 2 * 60 * 60 * 1000);
        await scheduleReminder(`${event.params.appointmentId}_review`, customerId, tsReview, "Com'è andata? ⭐", `Speriamo ti sia piaciuto il ${serviceName}! Lascia una recensione su Google Maps.`);
    }
    if (newStatus === "noShow") {
        const staffTokens = await getStaffTokens();
        await sendToTokens(staffTokens, "Cliente non presentato", `${customerName} non si è presentato per ${serviceName} alle ${formatTime(date)}.`, { route: "/admin/appointments" });
    }
});
// ─── Trigger: appointment hard-deleted ───────────────────────────────────────
exports.onAppointmentDeleted = (0, firestore_1.onDocumentDeleted)("appointments/{appointmentId}", async (event) => {
    var _a;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const appointmentId = event.params.appointmentId;
    const date = data.date;
    const customerId = data.customerId;
    const serviceName = data.serviceName;
    // Cancel any pending reminders
    await deleteReminders(appointmentId);
    // Notify the customer
    const token = await getUserToken(customerId);
    if (!token)
        return;
    await sendToTokens([token], "Appuntamento cancellato", `Il tuo ${serviceName} del ${formatDate(date)} alle ${formatTime(date)} è stato cancellato.`, { route: "/appointments" });
});
// ─── Trigger: barber marks unavailable ───────────────────────────────────────
exports.onBarberUnavailable = (0, firestore_1.onDocumentUpdated)("barbers/{barberId}", async (event) => {
    var _a, _b, _c, _d;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const prevDates = (_c = before.unavailableDates) !== null && _c !== void 0 ? _c : [];
    const newDates = (_d = after.unavailableDates) !== null && _d !== void 0 ? _d : [];
    const added = newDates.filter((d) => !prevDates.includes(d));
    if (added.length === 0)
        return;
    const barberName = after.name;
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
            const token = await getUserToken(apt.customerId);
            if (!token)
                continue;
            await sendToTokens([token], "Appuntamento da riprogrammare", `${barberName} non sarà disponibile il ${dateStr}. Contattaci per riprogrammare il tuo ${apt.serviceName}.`, { route: "/appointments", appointmentId: doc.id });
        }
    }
});
// ─── Trigger: announcement → notify all clients ───────────────────────────────
// Admin writes to announcements/{id} → FCM sent to all clients
exports.onAnnouncementCreated = (0, firestore_1.onDocumentCreated)("announcements/{announcementId}", async (event) => {
    var _a, _b, _c;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const title = (_b = data.title) !== null && _b !== void 0 ? _b : "The Gentlemen";
    const body = data.body;
    if (!body)
        return;
    const snap = await db
        .collection("users")
        .where("role", "==", "client")
        .get();
    const tokens = [];
    snap.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token)
            tokens.push(token);
    });
    await sendToTokens(tokens, title, body, { route: "/" });
    // Mark as delivered
    await ((_c = event.data) === null || _c === void 0 ? void 0 : _c.ref.update({ sentAt: admin.firestore.FieldValue.serverTimestamp() }));
});
// ─── Scheduled: daily summary to each barber at 08:00 Rome time ──────────────
exports.dailyBarberSummary = (0, scheduler_1.onSchedule)({ schedule: "0 8 * * *", timeZone: "Europe/Rome" }, async () => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    // Get all barbers
    const barbersSnap = await db.collection("barbers").get();
    for (const barberDoc of barbersSnap.docs) {
        const barberId = barberDoc.id;
        const barberName = barberDoc.data().name;
        // Get today's appointments for this barber (pending + confirmed)
        const aptsSnap = await db
            .collection("appointments")
            .where("barberId", "==", barberId)
            .where("status", "in", ["pending", "confirmed"])
            .where("date", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
            .where("date", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
            .orderBy("date")
            .get();
        if (aptsSnap.empty)
            continue;
        const count = aptsSnap.size;
        const firstApt = aptsSnap.docs[0].data();
        const firstTime = formatTime(firstApt.date);
        const token = await getUserToken(barberId);
        if (!token)
            continue;
        await sendToTokens([token], `Buongiorno ${barberName}! 💈`, `Oggi hai ${count} appuntament${count === 1 ? "o" : "i"}. Il primo alle ${firstTime}.`, { route: "/calendar" });
    }
});
// ─── Scheduled: process pending reminders every 15 minutes ───────────────────
exports.processScheduledNotifications = (0, scheduler_1.onSchedule)("every 15 minutes", async () => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db
        .collection("scheduledNotifications")
        .where("scheduledFor", "<=", now)
        .where("sent", "==", false)
        .get();
    if (snap.empty)
        return;
    functions.logger.info(`Processing ${snap.size} scheduled notifications`);
    for (const doc of snap.docs) {
        const data = doc.data();
        const customerId = data.customerId;
        const title = data.title;
        const body = data.body;
        try {
            const token = await getUserToken(customerId);
            if (token) {
                await sendToTokens([token], title, body, { route: "/appointments" });
            }
        }
        catch (e) {
            functions.logger.error(`Error sending reminder ${doc.id}:`, e);
        }
        await doc.ref.update({ sent: true, sentAt: now });
    }
});
//# sourceMappingURL=index.js.map