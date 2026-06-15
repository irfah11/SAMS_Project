const { launch, gotoApp, login, enableSemantics, dumpSemantics } = require('./helpers');
const fs = require('fs');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[flt-tappable]').forEach(el => {
      const r = el.getBoundingClientRect();
      out.push({ text: el.textContent.trim(), x: r.x, y: r.y, w: r.width, h: r.height });
    });
    return out;
  });
}

async function clickByText(page, text, exact = true) {
  await enableSemantics(page);
  const buttons = await getButtons(page);
  const btn = exact
    ? buttons.find(b => b.text === text)
    : buttons.find(b => b.text.includes(text));
  if (!btn) throw new Error('Button not found: ' + text + ' | available: ' + JSON.stringify(buttons.map(b=>b.text)));
  await page.mouse.click(btn.x + btn.w/2, btn.y + btn.h/2);
  await page.waitForTimeout(1200);
}

(async () => {
  const { browser, page, errors } = await launch();
  await gotoApp(page);
  await login(page, 'lecturer@sams.com', 'sams1234');
  await page.waitForTimeout(2000);
  await enableSemantics(page);

  // Open drawer -> Manage Attendance
  await clickByText(page, '', true); // hamburger (empty text)
  await clickByText(page, 'Manage Attendance', true);

  await page.screenshot({ path: 'screens/07_manage_attendance.png' });

  // Click "Software Engineering" subject card
  await clickByText(page, 'Software Engineering\nAcademic Subject', true);
  await page.waitForTimeout(1000);
  await enableSemantics(page);

  await page.screenshot({ path: 'screens/08_subject_sessions.png' });
  console.log('=== SUBJECT SESSIONS SEMANTICS ===');
  console.log(JSON.stringify(await dumpSemantics(page), null, 1));

  console.log('=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
