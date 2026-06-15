const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  await db.collection('AttendanceSession').doc('CJtBhpI8qxootc6nPGxa').update({
    is_online: true,
  });
  console.log('set is_online: true');
  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
