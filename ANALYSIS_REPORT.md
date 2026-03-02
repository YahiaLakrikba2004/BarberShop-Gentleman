# BarberShop-Gentleman: Feature Analysis Report
**Data:** March 2, 2026

---

## 📋 Executive Summary

Analisi dello stato di quattro aree critiche richieste:
1. **Notifiche in background** ⚠️ Partially Implemented
2. **Gestione email** ❌ Not Implemented
3. **Blocco 2 prenotazioni/settimana** ✅ Fully Implemented
4. **Gestione malattia barbieri** ⚠️ Semi-Automated (UI presente, no auto-cancellation)

---

## 1️⃣ NOTIFICHE SENZA APP IN BACKGROUND

### Status: ⚠️ **Partially Working**

**File principale:** [lib/services/notification_service.dart](lib/services/notification_service.dart)

### Cosa è implementato:
✅ Firebase Cloud Messaging (FCM) setup  
✅ Background message handler registrato in main.dart (line 32):
```dart
FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler);
```
✅ Local notifications scheduling with `AndroidScheduleMode.exactAllowWhileIdle`  
✅ Foreground message handling (FirebaseMessaging.onMessage)  
✅ Background/Terminated handler (FirebaseMessaging.onMessageOpenedApp)  
✅ FCM token saved to Firestore per user

### Cosa MANCA / POTREBBE ESSERE MIGLIORATO:
❌ **iOS APNS Configuration** - Code shows warning:
```dart
if (apnsToken == null && kDebugMode) {
    print('WARNING: APNS Token is null. Push notifications will NOT work...');
}
```

❌ **Background Android Permissions** - Richiede `android/app/src/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

⚠️ **Battery Optimization** - Android may kill background notifications se app è in low-power mode

### Problemi comuni:
- Se app non è in whitelist di Android per battery optimization → notifiche non arrivano
- Se APNS token è nullo su iOS → le notifiche push non funzionano

### Testing Checklist:
- [ ] Verificare che `android/app/src/AndroidManifest.xml` ha SCHEDULE_EXACT_ALARM e POST_NOTIFICATIONS permissions
- [ ] Su iOS: Verificare che APNS è configurato in Firebase Console
- [ ] Testare con app chiusa (terminated state)
- [ ] Verificare FCM token in Firestore (db → users → [userId] → fcmToken)

---

## 2️⃣ GESTIONE EMAIL

### Status: ❌ **Not Implemented**

**File principale:** [lib/services/notification_service.dart](lib/services/notification_service.dart)

### Cosa è implementato:
✅ Email field in UserModel (opzionale)  
✅ Email FAKE generato per login: `'+39123456789'@gentleman.app` (auth_screen.dart, line 89)

### Cosa MANCA:
❌ **NO Email Sending Service** - Non esiste un servizio per inviare email  
❌ **NO Backend Email Logic** - Firebase Functions non implementate  
❌ **NO SMTP Integration** - Nessun provider (SendGrid, Mailgun, AWS SES)

### Cosa esiste invece:
✅ WhatsApp messaging via [lib/services/messaging_service.dart](lib/services/messaging_service.dart)
- Usato nel barber_management_screen per avvisare clienti manualmente
- Quando admin preme "WhatsApp icon" → invia messaggio di cancellazione appuntamento

### Dove email sarebbe utile:
1. Conferma prenotazione al cliente
2. Reminder 24h prima
3. Cambio/Cancellazione appuntamento
4. Password reset (attualmente usa Firebase Email, ma email è fake)

### To Implement Email:
**Option 1: Firebase Extensions (Easiest)**
- Usa "Email" extension in Firebase Console
- Trigger on appointment creation → send email

**Option 2: Firebase Cloud Functions + SendGrid**
- Create `functions/sendConfirmationEmail.js`
- Trigger on `appointments.onCreate`
- Call SendGrid API

**Option 3: Direct Firestore Trigger + Backend**
- Backend service (Node.js/Python) listens to Firestore changes
- Sends email for each event

---

## 3️⃣ BLOCCO 2 PRENOTAZIONI PER SETTIMANA

### Status: ✅ **Fully Implemented & Working**

**File principale:** [lib/features/booking/booking_screen.dart](lib/features/booking/booking_screen.dart)

### Implementazione:

**Logic:**
```dart
// Line 1580+ in _confirmBooking()
final allAppointments = await ref.read(firestoreServiceProvider)
    .getAllAppointmentsForCustomer(userId)
    .first;

// Count appointments THIS WEEK
final weekStart = _selectedSlot!.subtract(Duration(days: _selectedSlot!.weekday - 1));
final weekEnd = weekStart.add(const Duration(days: 7));

final weeklyCount = allAppointments.where((apt) {
  return apt.status == AppointmentStatus.confirmed &&
         apt.date.isAfter(weekStart) &&
         apt.date.isBefore(weekEnd);
}).length;

if (weeklyCount >= 2) {
  setState(() {
    _bookingBlocked = true;
    // Show blocked screen with "LIMITE RAGGIUNTO"
  });
  return;
}
```

### Comportamento:
✅ Conta appuntamenti confermati della settimana corrente  
✅ Se count >= 2 → Blocca booking e mostra schermata rossa "LIMITE RAGGIUNTO"  
✅ Mostra spiegazione: "Hai raggiunto il limite di 2 prenotazioni per questa settimana"  
✅ Permette di tornare indietro per scegliere settimana successiva

### Visual Feedback:
- Schermata dedicata con icona rossa rotante
- Countdown timer fino a ritorno a home
- Messaggio cortese di ricontatto

✅ **Questo è COMPLETAMENTE IMPLEMENTATO E FUNZIONANTE**

---

## 4️⃣ GESTIONE MALATTIA/ASSENZA BARBIERI

### Status: ⚠️ **Partially Automated (UI + Manual Override)**

**File principale:** [lib/features/admin/barber_management_screen.dart](lib/features/admin/barber_management_screen.dart)

### Modello supportato:
```dart
enum BarberAvailability {
  available,
  sick,           // Malattia
  vacation,       // Ferie
  dayOff,         
  absence,        // Assenza generica
}
```

### Flusso quando Admin cambia stato a "Sick":

1. **Conflitti rilevati** (line 282):
   - Controlla ALL appuntamenti del barbiere
   - Identifica appuntamenti confermati nei prossimi 7 giorni

2. **Se NO conflitti:**
   - Cambia stato del barbiere subito
   - Mostra: "Stato aggiornato: Malattia"

3. **Se CI SONO conflitti:**
   - Mostra dialog con lista di appuntamenti conflittuali
   - Per ogni appuntamento, admin può:
     - 🟢 **WhatsApp**: Invia messaggio automatico al cliente:
       ```
       "Ciao Mario, sono Giovanni.
       Purtroppo non sto bene e non ci sarò per il tuo appuntamento 
       del 05/03 alle 14:00. Scusami, contattaci per spostarlo."
       ```
     - 🔴 **Delete**: Annulla manualmente l'appuntamento
   - Button "FORZA": Cambia stato senza annullare (preserva appuntamenti)

### Cosa MANCA (Automazione):
❌ **NO Auto-Cancellation** - Appuntamenti non vengono cancellati automaticamente  
❌ **NO Automatic Rescheduling** - Cliente deve contattare manualmente  
❌ **NO Email Notifications** - Solo WhatsApp (che è manuale)  
❌ **NO Cascade Updates** - Se si cancella appuntamento, cliente non riceve notifica

### Cosa ESISTE (Manuale):
✅ UI intuitiva in Barber Management Screen  
✅ Conflitto detection su 7 giorni  
✅ WhatsApp messaging integrato  
✅ Manual cancel per ogni appuntamento  
✅ Availability status persistence in Firestore

### Scenari Attuali:

**Scenario 1: Admin marca barbiere come "Sick" (Proposto)**
```
Admin clicks "Malattia"
→ System detects conflicts
→ Dialog shows appointments
→ Admin decides per appointment (WhatsApp OR Delete OR Ignore)
→ Admin clicks "FORZA" to mark sick anyway
→ Barber status changes to "sick"
→ Customers are left with their appointments (BUT barber is marked unavailable for booking)
```

**Problema**: Cliente ha ancora appuntamento, barbiere è marcato malato → Inconsistenza!

### Recommendation: Semi-Automated System

Option A: **Mandatory Auto-Cancel (if marked sick)**
```dart
if (status == BarberAvailability.sick || status == BarberAvailability.vacation) {
  // Auto-delete all conflicting appointments
  for (var apt in conflicting) {
    await deleteAppointment(apt.id);
    // Send WhatsApp notification
    messagingService.sendWhatsAppMessage(apt.customerPhone, "Your appointment was cancelled because...");
  }
}
```

Option B: **Require Admin Action (Current)**
- Keep manual process
- Add checkbox: "Auto-notify customers" (sends WhatsApp to all)
- Add dropdown: "Action" → [Notify Only, Notify + Keep, Notify + Cancel]

---

## 📊 Summary Table

| Feature | Status | Implementation | Automation | Priority |
|---------|--------|-----------------|-----------|----------|
| Background Notifications | ⚠️ Partial | FCM + Local | Yes | HIGH |
| Email System | ❌ Missing | - | - | MEDIUM |
| Weekly Booking Limit | ✅ Complete | Client-side filter | Yes | LOW (Done) |
| Barber Sick Leave | ⚠️ Partial | UI + Manual | Manual Only | HIGH |

---

## 🎯 Next Steps Recommended

### PRIORITY 1 (Critical):
1. **Fix Background Notifications**
   - Verify AndroidManifest.xml has SCHEDULE_EXACT_ALARM
   - Test on real device with app killed
   - Verify APNS on iOS

2. **Implement Email Service**
   - Setup Firebase Extensions Email OR
   - Create Cloud Functions with SendGrid/Mailgun
   - Trigger on appointment creation/cancellation

3. **Automate Barber Sick Leave**
   - Add auto-cancel option when marking sick
   - Send notification to customers
   - Update appointment status to "cancelled"

### PRIORITY 2 (Nice to Have):
- Add email reminders (24h before appointment)
- Add SMS fallback if WhatsApp fails
- Create admin dashboard for sick days/vacations

---

## 📁 Code Locations Reference

```
lib/
├── services/
│   ├── notification_service.dart (Firebase + Local)
│   ├── messaging_service.dart (WhatsApp)
│   └── firestore_service.dart (Data)
├── features/
│   ├── booking/booking_screen.dart (Weekly limit check)
│   └── admin/barber_management_screen.dart (Sick/Vacation management)
└── models/
    └── barber_model.dart (Availability enum)

firebase/
├── functions/
│   └── index.js (Could add email functions here)
```

---

**Report generated:** 2026-03-02  
**Next review:** After implementing Priority 1 items
