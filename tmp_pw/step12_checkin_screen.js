const { launch, gotoApp, login, enableSemantics } = require('./helpers');

async function getButtons(page) {
  return await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"], flt-semantics[role="link"], flt-semantics[role="switch"], flt-semantics[role="checkbox"], flt-semantics[role="textbox"]').forEach(el => {
      const r = el.getBoundingClientRect();
      const text = (el.textContent || '').trim();
      const role = el.getAttribute('role');
      if (r.width > 0 && r.height > 0) {
        out.push({ text, role, x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2), w: Math.round(r.width), h: Math.round(r.height) });
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
    await page.screenshot({ path: 'screens/16_student_session_list.png' });
    btns = await getButtons(page);
    console.log('Student session list:', JSON.stringify(btns));

    // Click on the session row (time/desc cell) to navigate to check-in
    const sessionRow = btns.find(b => b.text.includes('Regular class session') || b.text.includes('Pending') || b.text.includes('Active'));
    if (!sessionRow) throw new Error('Session row not found');
    await clickAt(page, sessionRow.x, sessionRow.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/17_checkin_screen.png' });
    btns = await getButtons(page);
    console.log('Check-in screen buttons:', JSON.stringify(btns));

    // Dump full semantics + inputs
    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        if (r.width > 0 && r.height > 0 && (text || role)) out.push({role, text, x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height)});
      });
      document.querySelectorAll('input').forEach(el => {
        const r = el.getBoundingClientRect();
        out.push({input: true, label: el.getAttribute('aria-label'), x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height)});
      });
      return out;
    });
    console.log('Full check-in screen elements:', JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step12.png' });
  } finally {
    await browser.close();
  }
})();
