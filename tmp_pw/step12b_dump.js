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
    await login(page, 'student@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    const attBtn = btns.find(b => b.text.includes('Attendance'));
    await clickAt(page, attBtn.x, attBtn.y);
    btns = await getButtons(page);
    const checkIn = btns.find(b => b.text === 'Check In');
    await clickAt(page, checkIn.x, checkIn.y);
    btns = await getButtons(page);
    const subj = btns.find(b => b.text.includes('Software Engineering'));
    await clickAt(page, subj.x, subj.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/16_student_session_list.png' });

    // dump everything with non-empty text or with a role
    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        const tappable = el.getAttribute('flt-tappable') !== null;
        if (r.width > 0 && r.height > 0) out.push({role, tappable, text: text.slice(0,80), x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height)});
      });
      return out;
    });
    console.log(JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
  } finally {
    await browser.close();
  }
})();
