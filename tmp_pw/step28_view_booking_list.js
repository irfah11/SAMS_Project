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
async function getFullText(page) {
  return await page.evaluate(() => {
    const seen = new Set();
    const out = [];
    document.querySelectorAll('flt-semantics').forEach(el => {
      const r = el.getBoundingClientRect();
      const text = (el.textContent || '').trim();
      if (r.width > 0 && r.height > 0 && text && !seen.has(text)) {
        seen.add(text);
        out.push(text.slice(0, 200));
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
    await login(page, 'student@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    await clickAt(page, btns.find(b => b.text === 'My Co-Q').x, btns.find(b => b.text === 'My Co-Q').y);
    await page.waitForTimeout(500);
    btns = await getButtons(page);
    console.log('Drawer buttons after expanding My Co-Q:', JSON.stringify(btns.map(b=>b.text)));
    const viewBookingBtn = btns.find(b => b.text === 'View Booking List');
    await clickAt(page, viewBookingBtn.x, viewBookingBtn.y);
    await page.waitForTimeout(1000);
    await enableSemantics(page);

    const content = await getFullText(page);
    console.log('View Booking List content:', JSON.stringify(content, null, 1));
    await page.screenshot({ path: 'screens/39_view_booking_list.png' });

    btns = await getButtons(page);
    console.log('Buttons on this screen:', JSON.stringify(btns, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step28.png' });
  } finally {
    await browser.close();
  }
})();
