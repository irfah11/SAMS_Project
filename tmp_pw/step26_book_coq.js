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
    await login(page, 'student@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);

    // Open drawer
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    console.log('Drawer:', JSON.stringify(btns.map(b=>b.text)));

    // Expand "My Co-Q"
    const myCoq = btns.find(b => b.text === 'My Co-Q');
    await clickAt(page, myCoq.x, myCoq.y);
    btns = await getButtons(page);
    console.log('After My Co-Q expand:', JSON.stringify(btns.map(b=>b.text)));

    const bookSlot = btns.find(b => b.text === 'Booking Slot');
    await clickAt(page, bookSlot.x, bookSlot.y);
    await page.waitForTimeout(800);
    await page.screenshot({ path: 'screens/37_booking_slot.png' });
    btns = await getButtons(page);
    console.log('Booking slot screen:', JSON.stringify(btns.map(b=>b.text)));
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step26.png' });
  } finally {
    await browser.close();
  }
})();
