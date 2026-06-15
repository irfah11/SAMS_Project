const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  console.log('=== All course_registrations ===');
  const regSnap = await db.collection('course_registrations').get();
  regSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n=== course_subjects where subject_id == BCS2133 ===');
  const subjSnap = await db.collection('course_subjects')
    .where('subject_id', '==', 'BCS2133')
    .get();
  subjSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n=== student doc for CB23041 ===');
  const stuSnap = await db.collection('student')
    .where('student_id', '==', 'CB23041')
    .get();
  stuSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
