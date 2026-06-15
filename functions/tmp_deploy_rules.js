const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

(async () => {
  const projectId = serviceAccount.project_id;
  const { access_token } = await admin.app().options.credential.getAccessToken();
  const content = fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8');

  // 1. Create a new ruleset
  const createRes = await fetch(
    `https://firebaserules.googleapis.com/v1/projects/${projectId}/rulesets`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        source: { files: [{ name: 'firestore.rules', content }] },
      }),
    }
  );
  const ruleset = await createRes.json();
  if (!ruleset.name) {
    console.error('Create ruleset failed:', JSON.stringify(ruleset, null, 2));
    process.exit(1);
  }
  console.log('Created ruleset:', ruleset.name);

  // 2. Point the cloud.firestore release at the new ruleset
  const relRes = await fetch(
    `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases/cloud.firestore`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        release: {
          name: `projects/${projectId}/releases/cloud.firestore`,
          rulesetName: ruleset.name,
        },
      }),
    }
  );
  const release = await relRes.json();
  console.log('Release update result:', JSON.stringify(release, null, 2));

  process.exit(0);
})().catch(e => { console.error('ERROR:', e.message || e); process.exit(1); });
