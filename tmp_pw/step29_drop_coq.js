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
    await page.waitForTimeout(3000);
    await enableSemantics(page);

    // Verify login succeeded - retry once if still on login screen
    let txt = await getFullText(page);
    if (txt.some(t => t.includes('SAMS LOGIN'))) {
      console.log('Login screen still showing, retrying login...');
      await login(page, 'student@sams.com', 'sams1234');
      await page.waitForTimeout(3000);
      await enableSemantics(page);
      txt = await getFullText(page);
    }
    console.log('Post-login content:', JSON.stringify(txt.slice(0,5)));

    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await enableSemantics(page);
    let btns = await getButtons(page);
    console.log('Drawer buttons:', JSON.stringify(btns.map(b=>b.text)));
    const myCoq = btns.find(b => b.text === 'My Co-Q');
    await clickAt(page, myCoq.x, myCoq.y);
    await page.waitForTimeout(500);
    btns = await getButtons(page);
    const viewBookingBtn = btns.find(b => b.text === 'View Booking List');
    await clickAt(page, viewBookingBtn.x, viewBookingBtn.y);
    await page.waitForTimeout(1000);
    await enableSemantics(page);

    // Click Drop button
    btns = await getButtons(page);
    console.log('Buttons before drop:', JSON.stringify(btns.map(b=>b.text)));
    const dropBtn = btns.find(b => b.text === 'Drop');
    await clickAt(page, dropBtn.x, dropBtn.y);
    await page.waitForTimeout(1500);
    await enableSemantics(page);

    const afterDrop = await getFullText(page);
    console.log('After Drop content:', JSON.stringify(afterDrop, null, 1));
    await page.screenshot({ path: 'screens/40_after_drop.png' });

    // Wait a bit more and re-check (live snapshot update)
    await page.waitForTimeout(1500);
    await enableSemantics(page);
    const afterDrop2 = await getFullText(page);
    console.log('After Drop content (2s later):', JSON.stringify(afterDrop2, null, 1));
    await page.screenshot({ path: 'screens/41_after_drop_2s.png' });
  } catch (e) {
    console.error('ERROR:', e.message);
    await page.screenshot({ path: 'screens/ERROR_step29.png' });
  } finally {
    await browser.close();
  }
})();
