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
  await page.waitForTimeout(1000);
  await enableSemantics(page);
}

(async () => {
  const { browser, page } = await launch();
  try {
    await page.goto('http://localhost:8766/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view, canvas', { timeout: 60000 });
    await page.waitForTimeout(2000);
    await enableSemantics(page);
    await login(page, 'adab@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'Attendance').x, btns.find(b => b.text === 'Attendance').y);
    btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'View Attendance').x, btns.find(b => b.text === 'View Attendance').y);
    await page.waitForTimeout(800);
    btns = await getButtons(page);
    const futsal = btns.find(b => b.text.includes('Futsal Training'));
    await clickAt(page, futsal.x, futsal.y);
    await page.waitForTimeout(800);

    // Click the session row's "Time & Date" cell to navigate to ListAttendance
    await page.mouse.click(120, 198);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    await page.screenshot({ path: 'screens/36_adab_attendance_records.png' });

    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        if (r.width > 0 && r.height > 0 && (text || role) && (role==='button'||role==='group'||role==='table'||role==='row')) out.push({role, text: text.slice(0,100)});
      });
      return out;
    });
    console.log('Attendance records screen:', JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step25.png' });
  } finally {
    await browser.close();
  }
})();
