const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

(async () => {
  const target = await auth.getUserByEmail('balqisazman@gmail.com');
  console.log('AUTH UID:', target.uid, '| email:', target.email);

  const userDoc = await db.collection('users').doc(target.uid).get();
  console.log('users/' + target.uid, '=>', userDoc.exists ? JSON.stringify(userDoc.data()) : 'NOT FOUND');

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
