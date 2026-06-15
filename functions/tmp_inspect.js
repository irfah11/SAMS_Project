const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

(async () => {
  console.log('=== AUTH USERS ===');
  const listUsersResult = await auth.listUsers(100);
  for (const u of listUsersResult.users) {
    console.log(u.uid, '|', u.email, '| verified:', u.emailVerified);
  }

  const collections = [
    'users',
    'course_subjects',
    'module_coq',
    'lecturer',
    'lecturers',
    'course_registrations',
    'module_coq_registrations',
    'AttendanceSession',
    'AttendanceRecord',
  ];
  for (const col of collections) {
    const snap = await db.collection(col).limit(25).get();
    console.log(`\n=== ${col} (${snap.size} docs) ===`);
    snap.forEach(doc => {
      console.log(doc.id, '=>', JSON.stringify(doc.data()));
    });
  }

  process.exit(0);
})().catch(e => { console.error('ERROR:', e); process.exit(1); });
