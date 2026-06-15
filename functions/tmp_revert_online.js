const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  await db.collection('AttendanceSession').doc('CJtBhpI8qxootc6nPGxa').update({
    is_online: admin.firestore.FieldValue.delete(),
  });
  console.log('removed is_online field (reverted to original state)');
  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
