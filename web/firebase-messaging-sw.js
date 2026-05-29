importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAFSiVC-CSY5GMWZDyKGJvi9ko7-i8p1w0",
  authDomain: "cafejob-6a969.firebaseapp.com",
  projectId: "cafejob-6a969",
  storageBucket: "cafejob-6a969.firebasestorage.app",
  messagingSenderId: "234748322219",
  appId: "1:234748322219:web:6bfd0511f59b67127e72ee"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Menerima pesan background ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});