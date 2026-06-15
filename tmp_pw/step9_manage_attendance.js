const { launch, gotoApp, login, enableSemantics } = require('./helpers');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"]').forEach(el => {
      const r = el.getBoundingClientRect();
      const text = (el.textContent || '').trim();
      if (r.width > 0 && r.height > 0) {
        out.push({ text, x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2), w: Math.round(r.width), h: Math.round(r.height) });
      }
    });
    return out;
  });
}

async function clickAt(page, x, y) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(1200);
  await enableSemantics(page);
}

(async () => {
  const { browser, page } = await launch();
  try {
    await gotoApp(page);
    await login(page, 'lecturer@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.mouse.click(1256, 28); // open drawer
    await page.waitForTimeout(1000);
    await enableSemantics(page);

    let btns = await getButtons(page);
    const ma = btns.find(b => b.text === 'Manage Attendance');
    await clickAt(page, ma.x, ma.y);
    await page.screenshot({ path: 'screens/09_manage_attendance.png' });
    btns = await getButtons(page);
    console.log('Manage Attendance screen:', JSON.stringify(btns));

    // Click "Software Engineering" card (text may include subtitle)
    const subj = btns.find(b => b.text.includes('Software Engineering'));
    if (!subj) throw new Error('Subject card not found. Buttons: ' + JSON.stringify(btns));
    await clickAt(page, subj.x, subj.y);
    await page.screenshot({ path: 'screens/10_subject_sessions.png' });
    btns = await getButtons(page);
    console.log('Subject sessions screen:', JSON.stringify(btns));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step9.png' });
  } finally {
    await browser.close();
  }
})();
