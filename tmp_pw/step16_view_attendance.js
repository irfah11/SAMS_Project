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
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'Manage Attendance').x, btns.find(b => b.text === 'Manage Attendance').y);
    btns = await getButtons(page);
    const subj = btns.find(b => b.text.includes('Software Engineering'));
    await clickAt(page, subj.x, subj.y);
    btns = await getButtons(page);
    console.log('Subject sessions (should show Active now):', JSON.stringify(btns));

    // Tap session tile -> action sheet -> View Class Attendant
    const session = btns.find(b => b.text.includes('Regular class session'));
    await clickAt(page, session.x, session.y);
    btns = await getButtons(page);
    console.log('Action sheet:', JSON.stringify(btns));

    const view = btns.find(b => b.text.includes('View Class Attendant'));
    await clickAt(page, view.x, view.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/21_view_attendance.png' });

    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        if (r.width > 0 && r.height > 0 && (text || role) && role !== null) out.push({role, text: text.slice(0,80)});
      });
      return out;
    });
    console.log('View attendance content:', JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step16.png' });
  } finally {
    await browser.close();
  }
})();
