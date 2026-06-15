const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const APP_ID = '1:696960893106:android:720aaff5a2010995af49ab';
const SHA1 = 'C9:55:59:27:72:CA:FF:AA:F2:5F:8C:AE:3F:F7:07:34:55:BB:82:1E'.replace(/:/g, '');
const SHA256 = 'EB:21:B1:AC:7C:03:7A:A6:AB:96:CF:EF:8D:D0:F3:C3:2A:FF:27:EB:1E:A0:32:16:8A:6B:4D:7A:7D:B9:06:AA'.replace(/:/g, '');

(async () => {
  const { access_token } = await admin.app().options.credential.getAccessToken();

  for (const [hash, certType] of [[SHA1, 'SHA_1'], [SHA256, 'SHA_256']]) {
    const res = await fetch(
      `https://firebase.googleapis.com/v1beta1/projects/sams-7a359/androidApps/${APP_ID}/sha`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ shaHash: hash, certType }),
      }
    );
    const json = await res.json();
    console.log(certType, res.status, JSON.stringify(json));
  }

  // List current SHA certs to confirm
  const listRes = await fetch(
    `https://firebase.googleapis.com/v1beta1/projects/sams-7a359/androidApps/${APP_ID}/sha`,
    { headers: { Authorization: `Bearer ${access_token}` } }
  );
  console.log('LIST:', JSON.stringify(await listRes.json(), null, 2));
})();
