const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

(async () => {
  const list = await auth.listUsers(200);
  const target = list.users.find(u => u.email === 'lecturer@sams.com');
  console.log('AUTH USER:', target ? `${target.uid} | ${target.email}` : 'NOT FOUND');

  if (target) {
    const userDoc = await db.collection('users').doc(target.uid).get();
    console.log('USERS DOC:', userDoc.exists ? JSON.stringify(userDoc.data(), null, 2) : 'NOT FOUND');
  }

  console.log('\n=== ALL users collection docs ===');
  const usersSnap = await db.collection('users').get();
  usersSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n=== student collection (limit 10) ===');
  const studentSnap = await db.collection('student').limit(10).get();
  studentSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
