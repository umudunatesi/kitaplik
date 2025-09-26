importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAOuSRxd_h0-AoaqlTo5nYrdjW5mjQISEI",
  authDomain: "otokutuphane-5d32a.firebaseapp.com",
  projectId: "otokutuphane-5d32a",
  storageBucket: "otokutuphane-5d32a.firebasestorage.app",
  messagingSenderId: "369170877451",
  appId: "1:369170877451:web:732cce6fbfbff596054b0e",
});

const messaging = firebase.messaging();
