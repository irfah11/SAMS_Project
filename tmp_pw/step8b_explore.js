const { launch, gotoApp, login, enableSemantics, dumpSemantics } = require('./helpers');

(async () => {
  const { browser, page } = await launch();
  try {
    await gotoApp(page);
    await login(page, 'lecturer@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screens/08b_dashboard.png', fullPage: false });

    const all = await page.evaluate(() => {
      const out = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const r = el.getBoundingClientRect();
        const text = (el.textContent || '').trim();
        const role = el.getAttribute('role');
        if (r.width > 0 && r.height > 0) {
          out.push({ text, role, x: Math.round(r.x + r.width/2), y: Math.round(r.y + r.height/2), w: Math.round(r.width), h: Math.round(r.height) });
        }
      });
      return out;
    });
    console.log(JSON.stringify(all, null, 1));
  } catch (e) {
    console.error('ERROR:', e.message);
  } finally {
    await browser.close();
  }
})();
