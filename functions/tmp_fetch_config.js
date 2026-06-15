const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const APP_ID = '1:696960893106:android:720aaff5a2010995af49ab';

(async () => {
  const { access_token } = await admin.app().options.credential.getAccessToken();
  const res = await fetch(
    `https://firebase.googleapis.com/v1beta1/projects/sams-7a359/androidApps/${APP_ID}/config`,
    { headers: { Authorization: `Bearer ${access_token}` } }
  );
  const json = await res.json();
  const content = Buffer.from(json.configFileContents, 'base64').toString('utf8');
  const outPath = path.join(__dirname, '..', 'android', 'app', 'google-services.json');
  fs.writeFileSync(outPath, content);
  console.log('Wrote', outPath);
  console.log(content);
})();
