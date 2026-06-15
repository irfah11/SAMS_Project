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
    await page.screenshot({ path: 'screens/35_adab_futsal_sessions.png' });
    btns = await getButtons(page);
    console.log('Futsal sessions:', JSON.stringify(btns.map(b=>b.text)));

    // Dump full table content (rows not exposed as button role)
    const full = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics[role="row"], flt-semantics[role="table"]').forEach(el => {
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        const r = el.getBoundingClientRect();
        out.push({role, text: text.slice(0,100), x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2)});
      });
      return out;
    });
    console.log('Table rows:', JSON.stringify(full, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step24.png' });
  } finally {
    await browser.close();
  }
})();
