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
    // Hard reload to bypass service worker cache
    await page.goto('http://localhost:8766/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view, canvas', { timeout: 60000 });
    await page.waitForTimeout(2000);
    await enableSemantics(page);

    await login(page, 'adab@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.screenshot({ path: 'screens/33_adab_dashboard.png' });

    // Open drawer
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    console.log('Adab drawer buttons:', JSON.stringify(btns.map(b=>b.text)));

    // Click Attendance to expand
    let attBtn = btns.find(b => b.text === 'Attendance');
    await clickAt(page, attBtn.x, attBtn.y);
    btns = await getButtons(page);
    console.log('After Attendance expand:', JSON.stringify(btns.map(b=>b.text)));

    const viewAtt = btns.find(b => b.text === 'View Attendance');
    if (!viewAtt) throw new Error('View Attendance not found');
    await clickAt(page, viewAtt.x, viewAtt.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/34_adab_coq_list.png' });
    btns = await getButtons(page);
    console.log('CoQ module list:', JSON.stringify(btns.map(b=>b.text)));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step23.png' });
  } finally {
    await browser.close();
  }
})();
