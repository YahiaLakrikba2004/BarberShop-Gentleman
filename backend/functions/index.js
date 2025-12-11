const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendAppointmentNotification = onDocumentCreated("appointments/{appointmentId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        return;
    }

    const appointment = snapshot.data();
    const userId = appointment.customerId;
    const barberId = appointment.barberId;

    // date might be a Firestore Timestamp
    const date = appointment.date.toDate();

    // Formatta la data e l'ora
    const formattedDate = date.toLocaleDateString("it-IT");
    const formattedTime = date.toLocaleTimeString("it-IT", {
        hour: "2-digit",
        minute: "2-digit",
    });

    try {
        // Recupera il token FCM dell'utente
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(userId).get();
        // Check if user exists and has a token
        if (!userDoc.exists) return null;

        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) {
            console.log("Nessun token FCM trovato per l'utente:", userId);
            return null;
        }

        // Recupera il nome del barbiere
        const barberDoc = await db.collection("barbers").doc(barberId).get();
        const barberName = barberDoc.exists ? barberDoc.data().name : "il tuo barbiere";

        const payload = {
            notification: {
                title: "Appuntamento Confermato! ✂️",
                body: `Il tuo taglio con ${barberName} è confermato per il ${formattedDate} alle ${formattedTime}.`,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "appointment_confirmation",
                appointmentId: event.params.appointmentId,
            },
            token: fcmToken,
        };

        const response = await getMessaging().send(payload);
        console.log("Notifica inviata con successo:", response);
        return { success: true };
    } catch (error) {
        console.error("Errore nell'invio della notifica:", error);
        return { error: error.message };
    }
});

exports.sendAppointmentCancellation = onDocumentDeleted("appointments/{appointmentId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        return;
    }

    const appointment = snapshot.data();
    const userId = appointment.customerId;
    const date = appointment.date.toDate();

    // Formatta la data e l'ora
    const formattedDate = date.toLocaleDateString("it-IT");
    const formattedTime = date.toLocaleTimeString("it-IT", {
        hour: "2-digit",
        minute: "2-digit",
    });

    try {
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(userId).get();
        const fcmToken = userDoc.exists ? userDoc.data().fcmToken : null;

        if (!fcmToken) return null;

        const payload = {
            notification: {
                title: "Appuntamento Cancellato ❌",
                body: `Il tuo appuntamento del ${formattedDate} alle ${formattedTime} è stato cancellato.`,
            },
            data: {
                type: "appointment_cancellation",
            },
            token: fcmToken,
        };

        const response = await getMessaging().send(payload);
        console.log("Notifica cancellazione inviata:", response);
        return { success: true };
    } catch (error) {
        console.error("Errore notifica cancellazione:", error);
        return { error: error.message };
    }
});

exports.sendAppointmentStatusUpdate = onDocumentUpdated("appointments/{appointmentId}", async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    const userId = newData.customerId;

    // Se lo stato non è cambiato, ignoriamo
    if (newData.status === oldData.status) return null;

    // Gestiamo solo stati rilevanti per l'utente
    if (newData.status !== "cancel" && newData.status !== "confirmed") return null;

    const date = newData.date.toDate();
    const formattedDate = date.toLocaleDateString("it-IT");
    const formattedTime = date.toLocaleTimeString("it-IT", {
        hour: "2-digit",
        minute: "2-digit",
    });

    let title = "Aggiornamento Appuntamento 📅";
    let body = `Lo stato del tuo appuntamento è cambiato.`;

    if (newData.status === "cancel") {
        title = "Appuntamento Cancellato ❌";
        body = `Il tuo appuntamento del ${formattedDate} alle ${formattedTime} è stato cancellato.`;
    } else if (newData.status === "confirmed") {
        title = "Appuntamento Confermato ✅";
        body = `Il tuo appuntamento del ${formattedDate} alle ${formattedTime} è confermato.`;
    }

    try {
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(userId).get();
        const fcmToken = userDoc.exists ? userDoc.data().fcmToken : null;

        if (!fcmToken) return null;

        const payload = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: "appointment_update",
                status: newData.status,
                appointmentId: event.params.appointmentId,
            },
            token: fcmToken,
        };

        const response = await getMessaging().send(payload);
        console.log("Notifica aggiornamento inviata:", response);
        return { success: true };
    } catch (error) {
        console.error("Errore notifica aggiornamento:", error);
        return { error: error.message };
    }
});
