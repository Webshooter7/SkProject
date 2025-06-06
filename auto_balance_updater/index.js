const admin = require("firebase-admin");
const { initializeApp, applicationDefault, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json"); // Downloaded from Firebase Console

admin.initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function updateBalance() {
  const now = new Date();
  const dateKey = now.toISOString().split("T")[0]; // YYYY-MM-DD
  const yesterday = new Date(now);
  yesterday.setDate(now.getDate() - 1);
  const yesterdayKey = yesterday.toISOString().split("T")[0];

  const prevDoc = await db.collection("daily_balances").doc(yesterdayKey).get();
  const openingGold = prevDoc.exists ? prevDoc.data().closingGold || 0 : 0;
  const openingSilver = prevDoc.exists ? prevDoc.data().closingSilver || 0 : 0;
  const openingCash = prevDoc.exists ? prevDoc.data().closingCash || 0 : 0;

  await db.collection("daily_balances").doc(dateKey).set({
    date: admin.firestore.Timestamp.now(),
    openingGold,
    openingSilver,
    openingCash,
    closingGold: openingGold,
    closingSilver: openingSilver,
    closingCash: openingCash
  });

  console.log(`Balance inserted for ${dateKey}`);
}

updateBalance().catch(console.error);
