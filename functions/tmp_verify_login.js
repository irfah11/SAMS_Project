const API_KEY = 'AIzaSyDNRaEm5JkpDMy0c789Ga5H6ulcv55t-fI';

(async () => {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'lecturer@sams.com',
        password: 'sams1234',
        returnSecureToken: true,
      }),
    }
  );
  const json = await res.json();
  console.log('STATUS:', res.status);
  console.log('localId (uid):', json.localId);
  console.log('email:', json.email);
  console.log(JSON.stringify(json, null, 2).slice(0, 1000));
})();
