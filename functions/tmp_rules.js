const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

(async () => {
  const projectId = serviceAccount.project_id;
  const { access_token } = await admin.app().options.credential.getAccessToken();

  // 1. Get the current release for cloud.firestore
  const relRes = await fetch(
    `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases/cloud.firestore`,
    { headers: { Authorization: `Bearer ${access_token}` } }
  );
  const release = await relRes.json();
  console.log('=== RELEASE ===');
  console.log(JSON.stringify(release, null, 2));

  if (release.rulesetName) {
    const rsRes = await fetch(
      `https://firebaserules.googleapis.com/v1/${release.rulesetName}`,
      { headers: { Authorization: `Bearer ${access_token}` } }
    );
    const ruleset = await rsRes.json();
    console.log('\n=== RULESET SOURCE ===');
    for (const f of ruleset.source?.files || []) {
      console.log(`--- ${f.name} ---`);
      console.log(f.content);
    }
    console.log('\ncreateTime:', ruleset.createTime);
  }

  process.exit(0);
})().catch(e => { console.error('ERROR:', e.message || e); process.exit(1); });
