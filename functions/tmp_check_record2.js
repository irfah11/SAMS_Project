const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  const snap = await db.collection('AttendanceRecord')
    .where('Student_id', '==', 'CB23038')
    .get();
  console.log(`Found ${snap.size} doc(s) with Student_id == CB23038`);
  snap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n--- Session doc ---');
  const sess = await db.collection('AttendanceSession').doc('CJtBhpI8qxootc6nPGxa').get();
  console.log(JSON.stringify(sess.data()));
  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
