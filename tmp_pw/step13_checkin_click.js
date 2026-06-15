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

    // Click on the "Description" cell of the session row (681, 214)
    await page.mouse.click(681, 214);
    await page.waitForTimeout(1200);
    await enableSemantics(page);
    await page.screenshot({ path: 'screens/17_checkin_screen.png' });

    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        if (r.width > 0 && r.height > 0 && (text || role)) out.push({role, text: text.slice(0,60), x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height)});
      });
      document.querySelectorAll('input').forEach(el => {
        const r = el.getBoundingClientRect();
        out.push({input: true, label: el.getAttribute('aria-label'), x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height)});
      });
      return out;
    });
    console.log(JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step13.png' });
  } finally {
    await browser.close();
  }
})();
