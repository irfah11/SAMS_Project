const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  console.log('=== course_registrations for CB23038 ===');
  const regSnap = await db.collection('course_registrations')
    .where('student_id', '==', 'CB23038')
    .get();
  regSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n=== module_coq_registrations for CB23038 ===');
  const coqRegSnap = await db.collection('module_coq_registrations')
    .where('student_id', '==', 'CB23038')
    .get();
  coqRegSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  const subjectIds = regSnap.docs.map(d => d.data().subject_id).filter(Boolean);
  console.log('\n=== AttendanceSession for subject_ids', subjectIds, '===');
  for (const sid of subjectIds) {
    const sessSnap = await db.collection('AttendanceSession')
      .where('subject_id', '==', sid)
      .get();
    sessSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));
  }

  console.log('\n=== AttendanceRecord for CB23038 ===');
  const recSnap = await db.collection('AttendanceRecord')
    .where('Student_id', '==', 'CB23038')
    .get();
  recSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
