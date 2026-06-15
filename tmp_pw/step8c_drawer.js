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

(async () => {
  const { browser, page } = await launch();
  try {
    await gotoApp(page);
    await login(page, 'lecturer@sams.com', 'sams1234');
    await page.waitForTimeout(2500);
    await enableSemantics(page);
    await page.waitForTimeout(500);

    // Click the unnamed button at top-right (x:1256,y:28) - likely menu/drawer toggle
    await page.mouse.click(1256, 28);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screens/08c_after_menu_click.png' });

    await enableSemantics(page);
    const btns = await getButtons(page);
    console.log('Buttons after click:', JSON.stringify(btns));
  } catch (e) {
    console.error('ERROR:', e.message);
  } finally {
    await browser.close();
  }
})();
