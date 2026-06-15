const { launch, gotoApp, login, enableSemantics, dumpSemantics } = require('./helpers');

(async () => {
  const { browser, page, errors } = await launch();
  await gotoApp(page);
  await login(page, 'lecturer@sams.com', 'sams1234');
  await page.waitForTimeout(2000);
  await enableSemantics(page);

  // Open drawer
  const buttons = await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"]').forEach(el => {
      const r = el.getBoundingClientRect();
      out.push({ text: el.textContent.trim(), x: r.x, y: r.y, w: r.width, h: r.height });
    });
    return out;
  });
  const menuBtn = buttons.find(b => b.text === '');
  await page.mouse.click(menuBtn.x + menuBtn.w/2, menuBtn.y + menuBtn.h/2);
  await page.waitForTimeout(1500);
  await enableSemantics(page);

  // Click "Manage Attendance"
  const drawerButtons = await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"]').forEach(el => {
      const r = el.getBoundingClientRect();
      out.push({ text: el.textContent.trim(), x: r.x, y: r.y, w: r.width, h: r.height });
    });
    return out;
  });
  console.log('DRAWER BUTTONS:', JSON.stringify(drawerButtons));
  const maBtn = drawerButtons.find(b => b.text === 'Manage Attendance');
  await page.mouse.click(maBtn.x + maBtn.w/2, maBtn.y + maBtn.h/2);
  await page.waitForTimeout(2000);
  await enableSemantics(page);

  await page.screenshot({ path: 'screens/06_manage_attendance.png', fullPage: true });
  console.log('=== MANAGE ATTENDANCE SEMANTICS ===');
  console.log(JSON.stringify(await dumpSemantics(page), null, 1));

  console.log('=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
