const admin = require('firebase-admin');
const { format, subDays } = require('date-fns');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json'); // JSON from GitHub secret
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  const today = format(new Date(), 'yyyy-MM-dd');
  const yesterday = format(subDays(new Date(), 1), 'yyyy-MM-dd');

  const todayDoc = db.collection('daily_balances').doc(today);
  const yesterdayDoc = db.collection('daily_balances').doc(yesterday);

  const todaySnapshot = await todayDoc.get();

  if (todaySnapshot.exists) {
    console.log(`[✔] Balance already exists for today: ${today}`);
    return;
  }

  const ySnap = await yesterdayDoc.get();

  if (!ySnap.exists) {
    console.warn(`[!] No balance data for yesterday: ${yesterday}`);
    return;
  }

  const data = ySnap.data();

  await todayDoc.set({
    openingGold: data.closingGold ?? 0,
    openingSilver: data.closingSilver ?? 0,
    openingCash: data.closingCash ?? 0,
    date: admin.firestore.Timestamp.now(),
  });

  console.log(`[+] Created today's balance from yesterday's data.`);
})();
