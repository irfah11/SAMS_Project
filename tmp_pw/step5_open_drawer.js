const { launch, gotoApp, login, enableSemantics, dumpSemantics } = require('./helpers');

(async () => {
  const { browser, page, errors } = await launch();
  await gotoApp(page);
  await login(page, 'lecturer@sams.com', 'sams1234');
  await page.waitForTimeout(2000);
  await enableSemantics(page);

  // Find all buttons with bounding boxes
  const buttons = await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('flt-semantics[role="button"]').forEach(el => {
      const r = el.getBoundingClientRect();
      out.push({
        id: el.id,
        text: el.textContent.trim(),
        x: r.x, y: r.y, w: r.width, h: r.height,
      });
    });
    return out;
  });
  console.log('BUTTONS:', JSON.stringify(buttons, null, 1));

  // Click the unlabeled button (likely the hamburger menu) - pick the one
  // with empty text and smallest area near top
  const menuBtn = buttons.find(b => b.text === '' );
  if (menuBtn) {
    console.log('Clicking menu button at', menuBtn.x + menuBtn.w/2, menuBtn.y + menuBtn.h/2);
    await page.mouse.click(menuBtn.x + menuBtn.w/2, menuBtn.y + menuBtn.h/2);
    await page.waitForTimeout(1500);
    await enableSemantics(page);
  }

  await page.screenshot({ path: 'screens/05_drawer.png', fullPage: true });
  console.log('=== AFTER MENU CLICK SEMANTICS ===');
  console.log(JSON.stringify(await dumpSemantics(page), null, 1));

  console.log('=== CONSOLE ERRORS ===');
  errors.forEach(e => console.log(e));

  await browser.close();
})().catch(e => { console.error('FATAL:', e); process.exit(1); });
