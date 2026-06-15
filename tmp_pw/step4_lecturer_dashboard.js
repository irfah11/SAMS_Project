const { launch, gotoApp, login, enableSemantics, dumpSemantics } = require('./helpers');

(async () => {
  const { browser, page, errors } = await launch();
  await gotoApp(page);
  await login(page, 'lecturer@sams.com', 'sams1234');

  await page.screenshot({ path: 'screens/04_dashboard.png', fullPage: true });
  console.log('=== DASHBOARD SEMANTICS ===');
  console.log(JSON.stringify(await dumpSemantics(page), null, 1));

  console.log('=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
