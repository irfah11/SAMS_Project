const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

(async () => {
  // 1. Bug #3 fix needs course_subjects.lecturer_name to match the
  //    lecturer@sams.com users doc's "name" field ("Test Lecturer").
  //    BCS2133 is the subject student CB23038 is Approved-registered for,
  //    and already has a Pending AttendanceSession (CJtBhpI8qxootc6nPGxa).
  await db.collection('course_subjects').doc('BCS2133').set(
    { lecturer_name: 'Test Lecturer' },
    { merge: true }
  );
  console.log('Updated course_subjects/BCS2133 -> lecturer_name: "Test Lecturer"');

  // 2. New Co-Q module owned by "Test Lecturer" so lecturer@sams.com has a
  //    CoQ activity to manage, and student@sams.com can Book it (Bug #4 fix).
  await db.collection('module_coq').doc('COQ001').set({
    coq_id: 'COQ001',
    activity_name: 'Futsal Training',
    booking_quota: 30,
    location: 'UMPSA Sports Complex',
    lecturer_name: 'Test Lecturer',
  });
  console.log('Created module_coq/COQ001 (Futsal Training, lecturer_name: "Test Lecturer")');

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
