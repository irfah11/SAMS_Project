const { launch, gotoApp, login } = require('./helpers');

(async () => {
  const { browser, page, errors } = await launch();
  await gotoApp(page);
  await page.screenshot({ path: 'screens/01_login.png' });

  await login(page, 'lecturer@sams.com', 'sams1234');
  await page.screenshot({ path: 'screens/02_after_login.png' });

  console.log('=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
