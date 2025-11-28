importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "INSERT_FIREBASE_WEB_API_KEY_HERE", // TODO: Replace with value from .env or Firebase Console
    authDomain: "barbershop-gentleman.firebaseapp.com",
    projectId: "barbershop-gentleman",
    storageBucket: "barbershop-gentleman.firebasestorage.app",
    messagingSenderId: "635305520200",
    appId: "1:635305520200:web:6c6c136aa05ff13af73c7d",
    measurementId: "G-75V0GQMVLC"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
