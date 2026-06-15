const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  console.log('=== module_coq_registrations (first 5) ===');
  const coqRegSnap = await db.collection('module_coq_registrations').limit(5).get();
  coqRegSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n=== module_coq (first 5) ===');
  const coqSnap = await db.collection('module_coq').limit(5).get();
  coqSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  console.log('\n=== AttendanceSession (all, just id/subject/coq/status) ===');
  const sessSnap = await db.collection('AttendanceSession').get();
  sessSnap.forEach(doc => {
    const d = doc.data();
    console.log(doc.id, '=> subject_id:', d.subject_id, '| coq_id:', d.coq_id, '| is_coq:', d.is_coq, '| status:', d.session_status);
  });

  console.log('\n=== course_registrations where subject_id==BCS2133 ===');
  const regSnap = await db.collection('course_registrations').where('subject_id','==','BCS2133').get();
  regSnap.forEach(doc => console.log(doc.id, '=>', JSON.stringify(doc.data())));

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
